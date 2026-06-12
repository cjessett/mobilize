# Asks "yes" RSVPs to confirm they're still coming, N days before the session
# (configured per event via confirmation_days_before).
class Event::ConfirmationJob < ApplicationJob
  queue_as :default

  def perform(session, scheduled_starts_at)
    return unless session.starts_at.to_i == scheduled_starts_at
    return if session.starts_at <= Time.current

    session.yes_rsvps.where(confirmed_at: nil).includes(:person).find_each do |rsvp|
      person = rsvp.person
      EventMailer.confirmation_request(rsvp).deliver_later if person.email.present? && !person.unsubscribed_email?

      next if person.phone.blank? || person.opted_out_sms?

      url = Rails.application.routes.url_helpers.rsvp_confirmation_url(token: rsvp.generate_token_for(:confirmation))
      body = "Can you still make it to #{session.event.title}? Tap to confirm: #{url}"
      Message.compose!(person: person, body: body, respect_texting_hours: true).deliver_later
    end
  end
end
