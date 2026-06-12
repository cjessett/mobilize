# Builds iCalendar (.ics) payloads for events. Times are emitted in UTC
# (calendar clients convert to the viewer's zone).
module IcsCalendar
  module_function

  def for_event(event, sessions: nil)
    wrap((sessions || event.event_sessions).flat_map { |session| vevent(event, session) })
  end

  def feed(organization, events)
    wrap(events.flat_map { |event| event.event_sessions.upcoming.flat_map { |session| vevent(event, session) } })
  end

  def wrap(vevents)
    ([ "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Mobilize//Events//EN", "CALSCALE:GREGORIAN" ] +
      vevents + [ "END:VCALENDAR" ]).join("\r\n") + "\r\n"
  end

  def vevent(event, session)
    summary = [ event.title, session.title.presence ].compact.join(" — ")
    description = [ event.description.presence, session.virtual_url.presence&.then { |u| "Join: #{u}" } ].compact.join("\n")
    [
      "BEGIN:VEVENT",
      "UID:mobilize-session-#{session.id}@#{Rails.application.routes.default_url_options[:host] || "mobilize"}",
      "DTSTAMP:#{timestamp(Time.current)}",
      "DTSTART:#{timestamp(session.starts_at)}",
      "DTEND:#{timestamp(session.ends_at || session.starts_at + 1.hour)}",
      "SUMMARY:#{escape(summary)}",
      (session.location.present? ? "LOCATION:#{escape(session.location)}" : nil),
      (description.present? ? "DESCRIPTION:#{escape(description)}" : nil),
      "END:VEVENT"
    ].compact
  end

  def timestamp(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def escape(text)
    text.to_s.gsub("\\", "\\\\\\\\").gsub("\n", '\n').gsub(",", '\,').gsub(";", '\;')
  end
end
