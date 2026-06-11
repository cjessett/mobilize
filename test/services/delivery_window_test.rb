require "test_helper"

class DeliveryWindowTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside) # America/Chicago, defaults 9-21 all days
    @person = people(:maria)
  end

  test "allows sending inside the window" do
    travel_to Time.utc(2026, 6, 10, 17, 0) do # noon Chicago
      assert_nil DeliveryWindow.next_allowed_time(person: @person, organization: @org)
    end
  end

  test "queues until the window opens the same day" do
    travel_to Time.utc(2026, 6, 10, 11, 0) do # 6am Chicago
      at = DeliveryWindow.next_allowed_time(person: @person, organization: @org)
      assert_equal 9, at.hour
      assert_equal at.to_date, Time.current.in_time_zone("America/Chicago").to_date
    end
  end

  test "queues to the next allowed day after hours" do
    travel_to Time.utc(2026, 6, 11, 3, 30) do # 10:30pm Wednesday Chicago
      at = DeliveryWindow.next_allowed_time(person: @person, organization: @org)
      assert_equal 9, at.hour
      assert_equal 4, at.wday # Thursday
    end
  end

  test "skips disallowed days" do
    @org.update!(texting_days: [ 1, 2, 3, 4, 5 ]) # weekdays only
    travel_to Time.utc(2026, 6, 13, 17, 0) do # Saturday noon Chicago
      at = DeliveryWindow.next_allowed_time(person: @person, organization: @org)
      assert_equal 1, at.wday # Monday
      assert_equal 9, at.hour
    end
  end

  test "uses the person's state time zone when present" do
    @person.update!(state: "CA")
    travel_to Time.utc(2026, 6, 10, 14, 0) do # 9am Chicago, 7am LA
      at = DeliveryWindow.next_allowed_time(person: @person, organization: @org)
      assert_not_nil at
      assert_equal "America/Los_Angeles", at.time_zone.tzinfo.name
    end
  end
end
