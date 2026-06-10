class Rsvp < ApplicationRecord
  STATUSES = %w[yes waitlist canceled].freeze

  belongs_to :event
  belongs_to :person

  validates :status, inclusion: { in: STATUSES }
  validates :person_id, uniqueness: { scope: :event_id }
end
