class Rsvp < ApplicationRecord
  STATUSES = %w[yes no maybe waitlist canceled].freeze

  belongs_to :event
  belongs_to :event_session
  belongs_to :person

  validates :status, inclusion: { in: STATUSES }
  validates :person_id, uniqueness: { scope: :event_session_id }

  generates_token_for :confirmation, expires_in: 60.days

  scope :going, -> { where(status: "yes") }

  def confirm!
    update!(confirmed_at: Time.current) if confirmed_at.nil?
  end
end
