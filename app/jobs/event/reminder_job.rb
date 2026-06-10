class Event::ReminderJob < ApplicationJob
  queue_as :default

  # scheduled_starts_at guards against reschedules: if the event moved after
  # this job was enqueued, a newer job exists for the new time.
  def perform(event, scheduled_starts_at)
    return unless event.starts_at.to_i == scheduled_starts_at
    return if event.starts_at <= Time.current

    time = event.starts_at.in_time_zone(event.organization.time_zone).strftime("%A %b %-d at %l:%M %p")
    event.yes_rsvps.includes(:person).find_each do |rsvp|
      person = rsvp.person
      next if person.phone.blank? || person.opted_out_sms?

      Message.compose!(person: person, body: "Reminder: #{event.title} is #{time}#{event.location.present? ? " at #{event.location}" : ""}. See you there!").deliver_later
    end
  end
end
