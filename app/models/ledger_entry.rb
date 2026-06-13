class LedgerEntry < ApplicationRecord
  ENTRY_TYPES = %w[topup charge refund adjustment].freeze

  belongs_to :organization
  belongs_to :message, optional: true

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :amount_microcents, presence: true
  validates :balance_after_microcents, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end
