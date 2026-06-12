class EventSession < ApplicationRecord
  belongs_to :event
  has_many :rsvps, dependent: :destroy

  validates :starts_at, presence: true

  scope :upcoming, -> { where(starts_at: Time.current..) }

  after_commit :schedule_notifications, on: [ :create, :update ], if: :saved_change_to_starts_at?

  def display_title
    title.presence || starts_at.in_time_zone(event.display_time_zone).strftime("%a %b %-d, %l:%M %p")
  end

  # Sessions inherit the event's location/link unless overridden.
  def location = super.presence || event.location
  def virtual_url = super.presence || event.virtual_url

  def upcoming? = starts_at > Time.current
  def yes_rsvps = rsvps.where(status: "yes")

  def full?
    event.capacity.present? && yes_rsvps.count >= event.capacity
  end

  def reminder_time = starts_at - 24.hours

  def confirmation_time
    return nil if event.confirmation_days_before.blank?

    starts_at - event.confirmation_days_before.days
  end

  private

  def schedule_notifications
    if reminder_time > Time.current
      Event::ReminderJob.set(wait_until: reminder_time).perform_later(self, starts_at.to_i)
    end
    if confirmation_time && confirmation_time > Time.current
      Event::ConfirmationJob.set(wait_until: confirmation_time).perform_later(self, starts_at.to_i)
    end
  end
end
