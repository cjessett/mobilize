module Billing
  # Settles the real cost of a delivered message: releases its pre-auth hold
  # and debits the actual Twilio price against the balance. Called from
  # Twilio's status callback. Idempotent — a message is only charged once.
  class ChargeMessage
    def initialize(message)
      @message = message
    end

    def call(twilio_price: nil)
      org = @message.organization
      return unless org.sms_billable?
      return if @message.cost_microcents.present?

      provider_cost = if twilio_price.present?
        Money.from_twilio_price(twilio_price)
      else
        Sms::Pricing.estimate_microcents(@message.body)
      end

      cost = Billing.with_markup(provider_cost, org.sms_markup_bps)

      @message.update!(
        provider_cost_microcents: provider_cost,
        cost_microcents: cost,
        num_segments: Sms::Pricing.segments(@message.body)
      )
      org.settle_sms_charge!(message: @message, amount_microcents: cost)
      AutoRecharge.new(org).call
    end
  end
end
