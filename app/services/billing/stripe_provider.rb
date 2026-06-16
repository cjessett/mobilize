module Billing
  # Thin wrapper over the Stripe API. Used only when STRIPE_SECRET_KEY is set;
  # otherwise FakeProvider stands in so the app is fully demoable offline.
  class StripeProvider
    def initialize(api_key:, webhook_secret: nil)
      require "stripe"
      Stripe.api_key = api_key
      @webhook_secret = webhook_secret
    end

    def create_customer(name:, email: nil, metadata: {})
      Stripe::Customer.create(name: name, email: email, metadata: metadata).id
    rescue Stripe::StripeError => e
      raise Error, e.message
    end

    def payment_method(customer_id)
      customer = Stripe::Customer.retrieve(customer_id)
      pm_id = customer.respond_to?(:invoice_settings) ? customer.invoice_settings&.default_payment_method : nil
      return nil if pm_id.blank?

      pm = Stripe::PaymentMethod.retrieve(pm_id)
      PaymentMethod.new(brand: pm.card.brand, last4: pm.card.last4, exp_month: pm.card.exp_month, exp_year: pm.card.exp_year)
    rescue Stripe::StripeError
      nil
    end

    # Hosted Checkout in "setup" mode to securely collect and save a card.
    def setup_checkout_url(customer:, success_url:, cancel_url:)
      session = Stripe::Checkout::Session.create(
        mode: "setup",
        customer: customer,
        success_url: success_url,
        cancel_url: cancel_url
      )
      session.url
    rescue Stripe::StripeError => e
      raise Error, e.message
    end

    # Charges the customer's saved default card off-session. Returns the
    # PaymentIntent id on success; raises Billing::Error otherwise.
    def charge(customer:, amount_cents:, description: nil)
      intent = Stripe::PaymentIntent.create(
        amount: amount_cents,
        currency: "usd",
        customer: customer,
        description: description,
        off_session: true,
        confirm: true
      )
      raise Error, "Payment was not completed (#{intent.status})." unless intent.status == "succeeded"

      intent.id
    rescue Stripe::StripeError => e
      raise Error, e.message
    end

    def verify_webhook(payload, signature)
      return nil if @webhook_secret.blank?

      Stripe::Webhook.construct_event(payload, signature, @webhook_secret)
    rescue Stripe::SignatureVerificationError, JSON::ParserError => e
      raise Error, e.message
    end

    # After a setup Checkout completes, promote the saved card to the
    # customer's default so future charges can run off-session.
    def set_default_payment_method_from_session(session)
      setup_intent = Stripe::SetupIntent.retrieve(session.setup_intent)
      Stripe::Customer.update(session.customer, invoice_settings: { default_payment_method: setup_intent.payment_method })
    rescue Stripe::StripeError
      nil
    end

    def fake? = false
  end
end
