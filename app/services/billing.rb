module Billing
  Error = Class.new(StandardError)
  PaymentMethod = Struct.new(:brand, :last4, :exp_month, :exp_year, keyword_init: true)

  class << self
    attr_writer :provider

    def provider
      @provider ||= build_provider
    end

    def configured?
      ENV["STRIPE_SECRET_KEY"].present?
    end

    # Applies the org's per-message markup (basis points; 0 = pass-through).
    def with_markup(provider_cost_microcents, markup_bps)
      (provider_cost_microcents * (10_000 + markup_bps.to_i) / 10_000.0).ceil
    end

    # Pre-send cost estimate (used to size the pre-auth hold), with markup.
    def estimated_cost(message)
      with_markup(Sms::Pricing.estimate_microcents(message.body), message.organization.sms_markup_bps)
    end

    private

    def build_provider
      if configured?
        StripeProvider.new(api_key: ENV["STRIPE_SECRET_KEY"], webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"])
      else
        FakeProvider.new
      end
    end
  end
end
