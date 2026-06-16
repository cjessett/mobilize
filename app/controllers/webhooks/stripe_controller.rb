class Webhooks::StripeController < ActionController::Base
  skip_forgery_protection

  def create
    event = Billing.provider.verify_webhook(request.body.read, request.headers["Stripe-Signature"].to_s)
    return head(:ok) if event.nil?

    case event.type
    when "checkout.session.completed"
      Billing.provider.set_default_payment_method_from_session(event.data.object)
    end
    head :ok
  rescue Billing::Error
    head :bad_request
  end
end
