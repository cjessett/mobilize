class EventCoHost < ApplicationRecord
  belongs_to :event
  belongs_to :organization

  validates :organization_id, uniqueness: { scope: :event_id }
  validate { errors.add(:organization, "already hosts this event") if event && organization_id == event.organization_id }
end
