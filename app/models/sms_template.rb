class SmsTemplate < ApplicationRecord
  include LanguageVariants

  belongs_to :organization
  belongs_to :event, optional: true

  validates :name, :body, presence: true

  scope :global, -> { where(event_id: nil) }
end
