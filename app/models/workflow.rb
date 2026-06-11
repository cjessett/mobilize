class Workflow < ApplicationRecord
  include Scopable

  TRIGGERS = %w[
    keyword_received tag_added form_submitted rsvp_created donation_created
    link_clicked person_created incoming_text event_attended email_opened
  ].freeze

  has_many :workflow_triggers, dependent: :destroy
  has_many :workflow_steps, -> { order(:position) }, dependent: :destroy
  has_many :workflow_runs, dependent: :destroy
  has_many :workflow_step_executions, through: :workflow_steps

  validates :name, presence: true

  scope :enabled, -> { where(enabled: true) }

  # Legacy single-trigger columns still work for programmatic creation; the
  # form UI manages workflow_triggers rows directly.
  after_save :sync_legacy_trigger, if: -> { saved_change_to_trigger? || saved_change_to_trigger_param? }

  # Fires all matching enabled workflows for an event. Enrollment is once per
  # person per workflow — re-firing for an already-enrolled person is a no-op
  # (delete the run from their profile to re-enroll them).
  def self.fire(trigger:, person:, param: nil, payload: {})
    achieve_goals(trigger: trigger, person: person, param: param)

    workflows = person.organization.workflows.enabled
      .joins(:workflow_triggers).where(workflow_triggers: { trigger: trigger }).distinct

    workflows.find_each do |workflow|
      next unless workflow.workflow_triggers.where(trigger: trigger).any? { |t| t.matches?(param: param, payload: payload) }
      next if workflow.workflow_steps.empty?

      begin
        run = workflow.workflow_runs.create!(person: person)
      rescue ActiveRecord::RecordNotUnique
        next
      end
      run.update!(current_step_id: Workflow::StepResolver.new(run).first_step&.id)
      Workflow::RunStepJob.perform_later(run)
    end
  end

  # A workflow with a goal exits a person's running enrollment as soon as the
  # goal event fires for them — remaining steps are skipped.
  def self.achieve_goals(trigger:, person:, param: nil)
    WorkflowRun.joins(:workflow)
      .where(person: person, status: "running")
      .where(workflows: { goal_trigger: trigger })
      .includes(:workflow).find_each do |run|
        goal_param = run.workflow.goal_param
        next if goal_param.present? && goal_param.to_s != param.to_s

        run.update!(status: "goal_met", goal_achieved_at: Time.current, finished_at: Time.current)
      end
  end

  def goal_rate
    finished = workflow_runs.where(status: %w[completed goal_met]).count
    return nil if finished.zero?

    (workflow_runs.where(status: "goal_met").count * 100.0 / finished).round
  end

  # Nested form/display representation: array of step hashes; router steps
  # carry "branches" => [{"name", "segment_id", "steps" => [...]}].
  def step_tree(parent: nil, branch_index: nil)
    scope = workflow_steps.where(parent_step_id: parent&.id, branch_index: branch_index).order(:position)
    scope.map do |step|
      hash = step.params.merge("action" => step.action, "id" => step.id)
      if step.router?
        hash["branches"] = step.branches.each_with_index.map do |branch, index|
          branch.merge("steps" => step_tree(parent: step, branch_index: index))
        end
      end
      hash
    end
  end

  private

  def sync_legacy_trigger
    return if trigger.blank?

    row = workflow_triggers.first_or_initialize
    row.update!(trigger: trigger, param: trigger_param)
  end
end
