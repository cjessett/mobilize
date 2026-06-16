require "test_helper"

class LedgerEntryTest < ActiveSupport::TestCase
  setup { @org = organizations(:riverside) }

  test "record_ledger_entry! credits and tracks running balance" do
    @org.update!(balance_microcents: 0)

    @org.record_ledger_entry!(entry_type: "topup", amount_microcents: Money.from_dollars(20), description: "Added $20.00")
    assert_equal Money.from_dollars(20), @org.reload.balance_microcents

    @org.record_ledger_entry!(entry_type: "charge", amount_microcents: -790, message: nil, description: "SMS")
    assert_equal Money.from_dollars(20) - 790, @org.reload.balance_microcents

    last = @org.ledger_entries.recent_first.first
    assert_equal "charge", last.entry_type
    assert_equal @org.balance_microcents, last.balance_after_microcents
  end

  test "billing_active? follows the stripe customer" do
    @org.update!(stripe_customer_id: nil)
    assert_not @org.billing_active?
    @org.update!(stripe_customer_id: "cus_x")
    assert @org.billing_active?
  end

  test "sms_billable? requires the feature flag and an active customer" do
    @org.update!(stripe_customer_id: "cus_x")
    assert @org.sms_billable?

    disable_billing_feature(@org)
    assert_not @org.sms_billable?

    FeatureFlags.provider = FeatureFlags::FakeProvider.new
    @org.update!(stripe_customer_id: nil)
    assert_not @org.sms_billable?
  end

  test "available balance subtracts held funds" do
    @org.update!(balance_microcents: Money.from_dollars(20), held_microcents: 5_000)
    assert_equal Money.from_dollars(20) - 5_000, @org.available_microcents
  end

  test "grant_credits! adds a positive grant entry" do
    @org.update!(balance_microcents: 0)
    @org.grant_credits!(amount_microcents: Money.from_dollars(50), description: "Paid cash")

    entry = @org.ledger_entries.recent_first.first
    assert_equal "grant", entry.entry_type
    assert_equal Money.from_dollars(50), @org.reload.balance_microcents
    assert_raises(ArgumentError) { @org.grant_credits!(amount_microcents: 0) }
  end
end
