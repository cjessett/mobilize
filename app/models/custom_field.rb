class CustomField < ApplicationRecord
  FIELD_TYPES = %w[text number boolean date].freeze

  belongs_to :organization

  normalizes :key, with: ->(value) { value.to_s.parameterize(separator: "_") }

  validates :key, presence: true, uniqueness: { scope: :organization_id }
  validates :label, presence: true
  validates :field_type, inclusion: { in: FIELD_TYPES }

  before_validation { self.key = label if key.blank? }
end
