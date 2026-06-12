class Event::ReminderJob < ApplicationJob
  queue_as :default

  # scheduled_starts_at guards against reschedules: if the session moved after
  # this job was enqueued, a newer job exists for the new time.
  def perform(session, scheduled_starts_at)
    return unless session.starts_at.to_i == scheduled_starts_at
    return if session.starts_at <= Time.current

    event = session.event
    time = session.starts_at.in_time_zone(event.display_time_zone).strftime("%A %b %-d at %l:%M %p")
    session.yes_rsvps.includes(:person).find_each do |rsvp|
      person = rsvp.person

      if person.phone.present? && !person.opted_out_sms?
        body = event.reminder_body_for(person.preferred_language).presence ||
          "Reminder: #{event.title} is #{time}#{session.location.present? ? " at #{session.location}" : ""}. See you there!"
        Message.compose!(person: person, body: body, respect_texting_hours: true).deliver_later
      end

      if person.email.present? && !person.unsubscribed_email?
        EventMailer.reminder(rsvp).deliver_later
      end
    end
  end
end
