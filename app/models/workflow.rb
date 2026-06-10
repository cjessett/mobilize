class Workflow < ApplicationRecord
  include Scopable

  TRIGGERS = %w[keyword_received tag_added form_submitted rsvp_created donation_created].freeze

  has_many :workflow_steps, -> { order(:position) }, dependent: :destroy
  has_many :workflow_runs, dependent: :destroy

  validates :name, presence: true
  validates :trigger, inclusion: { in: TRIGGERS }

  scope :enabled, -> { where(enabled: true) }

  # Fires all matching enabled workflows for an event. `param` matches
  # trigger_param when the workflow specifies one (e.g. a keyword word, a tag
  # name, a form id); workflows with a blank trigger_param match any param.
  def self.fire(trigger:, person:, param: nil)
    person.organization.workflows.enabled.where(trigger: trigger).find_each do |workflow|
      next if workflow.trigger_param.present? && workflow.trigger_param.to_s != param.to_s
      next if workflow.workflow_steps.empty?

      run = workflow.workflow_runs.create!(person: person)
      Workflow::RunStepJob.perform_later(run)
    end
  end
end
