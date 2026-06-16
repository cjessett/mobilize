require "test_helper"

class Sms::PricingTest < ActiveSupport::TestCase
  test "counts segments" do
    assert_equal 1, Sms::Pricing.segments("")
    assert_equal 1, Sms::Pricing.segments("hello")
    assert_equal 1, Sms::Pricing.segments("a" * 160)
    assert_equal 2, Sms::Pricing.segments("a" * 161)
  end

  test "estimates cost per segment" do
    assert_equal 790, Sms::Pricing.estimate_microcents("hi")
    assert_equal 1580, Sms::Pricing.estimate_microcents("a" * 161)
  end
end
