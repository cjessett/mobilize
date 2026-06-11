class WorkflowStepExecution < ApplicationRecord
  belongs_to :workflow_step
  belongs_to :workflow_run
  belongs_to :person

  validates :executed_at, presence: true
end
