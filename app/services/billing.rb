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
