class WorkflowRun < ApplicationRecord
  STATUSES = %w[running completed failed].freeze

  belongs_to :workflow
  belongs_to :person

  validates :status, inclusion: { in: STATUSES }
end
