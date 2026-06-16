require "test_helper"

class Billing::HoldsTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @org.update!(stripe_customer_id: "cus_x", balance_microcents: Money.from_dollars(1), held_microcents: 0)
  end

  test "reserve places a hold against available funds" do
    message = Message.compose!(person: people(:maria), body: "hi")

    assert @org.reserve_sms_hold!(2_000, message: message)
    assert_equal 2_000, @org.reload.held_microcents
    assert_equal 2_000, message.reload.hold_microcents
    assert_equal Money.from_dollars(1) - 2_000, @org.available_microcents
  end

  test "reserve fails when available funds are insufficient" do
    @org.update!(balance_microcents: 500)
    message = Message.compose!(person: people(:maria), body: "hi")

    assert_not @org.reserve_sms_hold!(2_000, message: message)
    assert_equal 0, @org.reload.held_microcents
    assert_nil message.reload.hold_microcents
  end

  test "settle releases the hold and charges the real cost" do
    message = Message.compose!(person: people(:maria), body: "hi")
    @org.reserve_sms_hold!(2_000, message: message)

    Billing::ChargeMessage.new(message).call(twilio_price: "-0.00750")

    @org.reload
    assert_equal 0, @org.held_microcents, "hold released"
    assert_equal Money.from_dollars(1) - 750, @org.balance_microcents, "charged actual price, not the held estimate"
    assert_equal 750, message.reload.cost_microcents
  end

  test "release returns held funds without charging" do
    message = Message.compose!(person: people(:maria), body: "hi")
    @org.reserve_sms_hold!(2_000, message: message)

    @org.release_sms_hold!(message)

    assert_equal 0, @org.reload.held_microcents
    assert_equal Money.from_dollars(1), @org.balance_microcents
    assert_nil message.reload.hold_microcents
  end

  test "reconcile job settles stale holds" do
    message = Message.compose!(person: people(:maria), body: "hi")
    @org.reserve_sms_hold!(2_000, message: message)
    message.update!(status: "sent", sent_at: 1.day.ago)

    Billing::ReconcileHoldsJob.new.perform

    assert_equal 0, @org.reload.held_microcents
    assert_not_nil message.reload.cost_microcents
  end
end
