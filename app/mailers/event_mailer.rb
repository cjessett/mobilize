class EventMailer < ApplicationMailer
  # Day-before reminder with calendar invite and (when confirmations are
  # enabled) a confirm button.
  def reminder(rsvp)
    set_context(rsvp)
    attach_invite
    mail(to: @person.email, subject: "Reminder: #{@event.title}", from: from_address)
  end

  def confirmation_request(rsvp)
    set_context(rsvp)
    mail(to: @person.email, subject: "Can you still make it to #{@event.title}?", from: from_address)
  end

  # Sent when an admin approves a supporter-submitted event.
  def host_approved(event)
    @event = event
    @host_tools_url = host_tools_url(token: event.host_token!)
    mail(to: event.submitted_by.email, subject: "Your event \"#{event.title}\" was approved", from: from_address)
  end

  private

  def set_context(rsvp)
    @rsvp = rsvp
    @event = rsvp.event
    @session = rsvp.event_session
    @person = rsvp.person
    @time = @session.starts_at.in_time_zone(@event.display_time_zone).strftime("%A %b %-d, %Y %l:%M %p %Z")
    @confirm_url = rsvp_confirmation_url(token: rsvp.generate_token_for(:confirmation))
  end

  def attach_invite
    attachments["#{@event.title.parameterize}.ics"] = {
      mime_type: "text/calendar",
      content: IcsCalendar.for_event(@event, sessions: [ @session ])
    }
  end

  def from_address
    ENV.fetch("MAIL_FROM", "no-reply@mobilize.test")
  end
end
