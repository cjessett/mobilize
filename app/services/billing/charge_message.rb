module Billing
  # Records the real cost of a delivered message against the org's balance.
  # Called from Twilio's status callback, where the final price is reported.
  # Idempotent: a message is only charged once.
  class ChargeMessage
    def initialize(message)
      @message = message
    end

    def call(twilio_price: nil)
      org = @message.organization
      return unless org.billing_active?
      return if @message.cost_microcents.present?

      provider_cost = if twilio_price.present?
        Money.from_twilio_price(twilio_price)
      else
        Sms::Pricing.estimate_microcents(@message.body)
      end

      cost = with_markup(provider_cost, org.sms_markup_bps)

      @message.update!(
        provider_cost_microcents: provider_cost,
        cost_microcents: cost,
        num_segments: Sms::Pricing.segments(@message.body)
      )
      org.record_ledger_entry!(
        entry_type: "charge",
        amount_microcents: -cost,
        message: @message,
        description: "SMS to #{@message.person.phone}"
      )
      AutoRecharge.new(org).call
    end

    private

    def with_markup(provider_cost, markup_bps)
      (provider_cost * (10_000 + markup_bps) / 10_000.0).ceil
    end
  end
end
