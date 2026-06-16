require "test_helper"

class BillingTest < ActiveSupport::TestCase
  setup { @org = organizations(:riverside) }

  test "topup charges the card and credits the balance" do
    @org.update!(balance_microcents: 0)

    Billing::Topup.new(@org, dollars: 20).call

    assert_equal Money.from_dollars(20), @org.reload.balance_microcents
    assert_equal 1, fake_billing.charges.size
    assert_equal 2000, fake_billing.charges.first[:amount_cents]
    entry = @org.ledger_entries.recent_first.first
    assert_equal "topup", entry.entry_type
    assert entry.stripe_payment_intent_id.start_with?("pi_fake_")
  end

  test "topup creates a stripe customer on first use" do
    @org.update!(stripe_customer_id: nil)
    Billing::Topup.new(@org, dollars: 10).call
    assert @org.reload.stripe_customer_id.present?
  end

  test "topup enforces a minimum" do
    assert_raises(Billing::Error) { Billing::Topup.new(@org, dollars: 1).call }
  end

  test "charge_message records twilio cost against the balance" do
    @org.update!(stripe_customer_id: "cus_x", balance_microcents: Money.from_dollars(20))
    message = Message.compose!(person: people(:maria), body: "hi")

    Billing::ChargeMessage.new(message).call(twilio_price: "-0.00750")

    message.reload
    assert_equal 750, message.provider_cost_microcents
    assert_equal 750, message.cost_microcents
    assert_equal Money.from_dollars(20) - 750, @org.reload.balance_microcents
  end

  test "charge_message applies markup" do
    @org.update!(stripe_customer_id: "cus_x", balance_microcents: Money.from_dollars(20), sms_markup_bps: 5000)
    message = Message.compose!(person: people(:maria), body: "hi")

    Billing::ChargeMessage.new(message).call(twilio_price: "-0.00800")

    # 800 microcents + 50% markup = 1200
    assert_equal 1200, message.reload.cost_microcents
  end

  test "charge_message is idempotent" do
    @org.update!(stripe_customer_id: "cus_x", balance_microcents: Money.from_dollars(20))
    message = Message.compose!(person: people(:maria), body: "hi")

    assert_difference -> { @org.ledger_entries.count }, 1 do
      2.times { Billing::ChargeMessage.new(message).call(twilio_price: "-0.00750") }
    end
  end

  test "charge_message is a no-op without active billing" do
    message = Message.compose!(person: people(:maria), body: "hi")
    assert_no_difference -> { LedgerEntry.count } do
      Billing::ChargeMessage.new(message).call(twilio_price: "-0.00750")
    end
    assert_nil message.reload.cost_microcents
  end
end
