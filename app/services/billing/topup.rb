module Billing
  # Charges the org's saved card and credits the prepaid balance. Because SMS
  # costs are fractions of a cent, billing is prepaid in dollars rather than
  # charging the card per message (Stripe's per-transaction fee would dwarf a
  # single text).
  class Topup
    MIN_DOLLARS = 5

    def initialize(organization, dollars:)
      @organization = organization
      @dollars = BigDecimal(dollars.to_s)
    end

    def call
      raise Error, "Minimum top-up is $#{MIN_DOLLARS}." if @dollars < MIN_DOLLARS

      customer = CustomerSetup.new(@organization).call
      payment_intent_id = Billing.provider.charge(
        customer: customer,
        amount_cents: (@dollars * 100).to_i,
        description: "#{@organization.name} balance top-up"
      )

      @organization.record_ledger_entry!(
        entry_type: "topup",
        amount_microcents: Money.from_dollars(@dollars),
        stripe_payment_intent_id: payment_intent_id,
        description: "Added #{Kernel.format('$%.2f', @dollars)}"
      )
    end
  end
end
