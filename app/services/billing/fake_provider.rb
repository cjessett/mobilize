module Billing
  # In-memory stand-in used in development and test when Stripe isn't
  # configured. Pretends a card is always on file and that charges succeed, so
  # the prepaid-balance flow is fully exercisable without a Stripe account.
  class FakeProvider
    attr_reader :charges, :customers

    def initialize
      @charges = []
      @customers = []
    end

    def create_customer(name:, email: nil, metadata: {})
      id = "cus_fake_#{SecureRandom.hex(8)}"
      @customers << { id: id, name: name }
      id
    end

    def payment_method(_customer_id)
      PaymentMethod.new(brand: "visa", last4: "4242", exp_month: 12, exp_year: 2099)
    end

    def setup_checkout_url(customer:, success_url:, cancel_url:)
      success_url
    end

    def charge(customer:, amount_cents:, description: nil)
      id = "pi_fake_#{SecureRandom.hex(8)}"
      @charges << { customer: customer, amount_cents: amount_cents, description: description, id: id }
      id
    end

    def verify_webhook(_payload, _signature) = nil

    def set_default_payment_method_from_session(_session) = nil

    def fake? = true
  end
end
