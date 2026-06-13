class Settings::BillingController < ApplicationController
  require_admin

  def show
    @organization = current_organization
    @entries = @organization.ledger_entries.recent_first.limit(50)
    @payment_method = @organization.stripe_customer_id.present? ? Billing.provider.payment_method(@organization.stripe_customer_id) : nil
  end

  def add_payment_method
    customer = Billing::CustomerSetup.new(current_organization).call
    url = Billing.provider.setup_checkout_url(
      customer: customer,
      success_url: settings_billing_url,
      cancel_url: settings_billing_url
    )
    redirect_to url, allow_other_host: true
  rescue Billing::Error => e
    redirect_to settings_billing_path, alert: e.message
  end

  def topup
    Billing::Topup.new(current_organization, dollars: params[:amount]).call
    redirect_to settings_billing_path, notice: "Funds added. New balance: #{current_organization.reload.balance_display}."
  rescue ArgumentError, TypeError
    redirect_to settings_billing_path, alert: "Enter a valid dollar amount."
  rescue Billing::Error => e
    redirect_to settings_billing_path, alert: e.message
  end
end
