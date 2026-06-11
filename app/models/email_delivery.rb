class EmailDelivery < ApplicationRecord
  STATUSES = %w[pending sent failed].freeze

  belongs_to :email_blast
  belongs_to :person

  validates :status, inclusion: { in: STATUSES }

  generates_token_for :open_tracking

  def mark_opened!
    return if opened_at.present?

    update!(opened_at: Time.current)
    Workflow.fire(trigger: "email_opened", person: person, param: email_blast_id)
  end
end
