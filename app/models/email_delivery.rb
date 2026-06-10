class EmailDelivery < ApplicationRecord
  STATUSES = %w[pending sent failed].freeze

  belongs_to :email_blast
  belongs_to :person

  validates :status, inclusion: { in: STATUSES }

  generates_token_for :open_tracking

  def mark_opened!
    update!(opened_at: Time.current) if opened_at.nil?
  end
end
