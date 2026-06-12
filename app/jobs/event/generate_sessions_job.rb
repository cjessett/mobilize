# Rolls recurring events forward: creates sessions on the event's frequency
# until the generation horizon (recurrence_days_ahead, capped by
# recurrence_until). Runs after event saves and daily via recurring.yml.
class Event::GenerateSessionsJob < ApplicationJob
  queue_as :default

  INTERVALS = { "daily" => 1.day, "weekly" => 1.week, "monthly" => 1.month }.freeze

  def self.generate_all
    Event.where.not(recurrence_frequency: "none").find_each { |event| perform_later(event) }
  end

  def perform(event)
    interval = INTERVALS[event.recurrence_frequency]
    return if interval.nil?

    horizon = Time.current + event.recurrence_days_ahead.days
    horizon = [ horizon, event.recurrence_until.end_of_day ].min if event.recurrence_until
    last = event.event_sessions.maximum(:starts_at)
    return if last.nil?

    duration = event.ends_at && event.starts_at ? event.ends_at - event.starts_at : nil
    100.times do
      last += interval
      break if last > horizon

      event.event_sessions.create!(starts_at: last, ends_at: duration ? last + duration : nil)
    end
  end
end
