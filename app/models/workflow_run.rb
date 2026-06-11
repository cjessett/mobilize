class WorkflowRun < ApplicationRecord
  STATUSES = %w[running completed failed goal_met].freeze

  belongs_to :workflow
  belongs_to :person
  belongs_to :current_step, class_name: "WorkflowStep", optional: true
  has_many :workflow_step_executions, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
end
