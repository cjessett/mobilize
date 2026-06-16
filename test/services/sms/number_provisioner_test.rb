require "test_helper"

class Sms::NumberProvisionerTest < ActiveSupport::TestCase
  setup { @chapter = chapters(:north) }

  test "provisions a number for an area code" do
    result = Sms::NumberProvisioner.new(@chapter).call(area_code: "415")

    @chapter.reload
    assert @chapter.phone_number.start_with?("+1415")
    assert @chapter.twilio_sid.start_with?("PNFAKE")
    assert_not_nil @chapter.provisioned_at
    assert_equal @chapter.phone_number, result[:phone_number]
  end

  test "raises when the area code is exhausted" do
    error = assert_raises(Sms::Error) { Sms::NumberProvisioner.new(@chapter).call(area_code: "000") }
    assert_match(/No numbers available/, error.message)
  end

  test "rejects malformed area codes" do
    assert_raises(Sms::Error) { Sms::NumberProvisioner.new(@chapter).call(area_code: "abc") }
    assert_raises(Sms::Error) { Sms::NumberProvisioner.new(@chapter).call(area_code: "41") }
  end

  test "charges the number cost when billing is active" do
    @chapter.organization.update!(stripe_customer_id: "cus_test", balance_microcents: Money.from_dollars(20))

    assert_difference -> { @chapter.organization.ledger_entries.count }, 1 do
      Sms::NumberProvisioner.new(@chapter).call(area_code: "415")
    end
    entry = @chapter.organization.ledger_entries.last
    assert_equal "charge", entry.entry_type
    assert_equal(-Sms::NumberProvisioner::NUMBER_PRICE_MICROCENTS, entry.amount_microcents)
  end

  test "does not charge when billing is inactive" do
    assert_no_difference -> { @chapter.organization.ledger_entries.count } do
      Sms::NumberProvisioner.new(@chapter).call(area_code: "415")
    end
  end
end
