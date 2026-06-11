# Computes whether a text may be sent right now under the organization's
# texting hours, evaluated in the recipient's approximate local time zone
# (state-based, falling back to the org's zone).
class DeliveryWindow
  # Returns nil when sending now is allowed, otherwise the next time the
  # window opens.
  def self.next_allowed_time(person:, organization:)
    zone = ActiveSupport::TimeZone[TimeZoneInference.zone_for(person).to_s] ||
      ActiveSupport::TimeZone[organization.time_zone.to_s] || Time.zone
    now = Time.current.in_time_zone(zone)

    start_hour = organization.texting_hours_start
    end_hour = organization.texting_hours_end
    days = Array(organization.texting_days).map(&:to_i)
    return nil if days.empty? || start_hour >= end_hour # misconfigured: don't hold messages

    return nil if days.include?(now.wday) && now.hour >= start_hour && now.hour < end_hour

    (0..7).each do |offset|
      day = now + offset.days
      next unless days.include?(day.wday)

      candidate = day.change(hour: start_hour)
      return candidate if candidate > now
    end
    nil
  end
end
