class Event < ApplicationRecord
  include Scopable

  belongs_to :host, class_name: "User", optional: true
  has_many :rsvps, dependent: :destroy
  has_many :attendees, through: :rsvps, source: :person

  validates :title, :starts_at, presence: true

  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }
  scope :past, -> { where(starts_at: ...Time.current).order(starts_at: :desc) }

  after_commit :schedule_reminder, on: [ :create, :update ], if: :saved_change_to_starts_at?

  def yes_rsvps = rsvps.where(status: "yes")

  def full?
    capacity.present? && yes_rsvps.count >= capacity
  end

  def rsvp_for!(person)
    rsvps.find_by(person: person) || begin
      rsvp = rsvps.create!(person: person, status: full? ? "waitlist" : "yes")
      Activity.record!(person: person, kind: "rsvp_created", subject: rsvp, data: { "event" => title })
      Workflow.fire(trigger: "rsvp_created", person: person, param: id)
      rsvp
    end
  end

  def reminder_time
    starts_at - 24.hours
  end

  private

  def schedule_reminder
    return if reminder_time <= Time.current

    Event::ReminderJob.set(wait_until: reminder_time).perform_later(self, starts_at.to_i)
  end
end
