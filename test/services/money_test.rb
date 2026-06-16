require "test_helper"

class MoneyTest < ActiveSupport::TestCase
  test "dollars convert to microcents" do
    assert_equal 2_000_000, Money.from_dollars(20)
    assert_equal 500_000, Money.from_dollars("5")
  end

  test "twilio price converts to microcents" do
    assert_equal 750, Money.from_twilio_price("-0.00750")
    assert_equal 790, Money.from_twilio_price("-0.0079")
  end

  test "microcents convert to cents for stripe" do
    assert_equal 2000, Money.to_cents(2_000_000)
    assert_equal 1, Money.to_cents(790) # 0.79 cents rounds to 1
  end

  test "format shows sub-cent precision for tiny amounts" do
    assert_equal "$0.00790", Money.format(790)
    assert_equal "$20.00", Money.format(2_000_000)
    assert_equal "$0.00", Money.format(0)
  end
end
