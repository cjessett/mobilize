class Settings::BillingController < ApplicationController
  require_admin
  require_superadmin only: :grant
  before_action :require_billing_feature

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

  # Superadmin-only: credit an org without charging a card (e.g. paid in cash).
  def grant
    dollars = BigDecimal(params[:amount].to_s)
    raise ArgumentError if dollars <= 0

    current_organization.grant_credits!(
      amount_microcents: Money.from_dollars(dollars),
      description: "Credit grant#{params[:note].present? ? ": #{params[:note]}" : ''}"
    )
    redirect_to settings_billing_path, notice: "Granted #{Money.format(Money.from_dollars(dollars))} in credits."
  rescue ArgumentError, TypeError
    redirect_to settings_billing_path, alert: "Enter a valid grant amount."
  end

  private

  def require_billing_feature
    return if current_organization&.billing_feature_enabled?

    redirect_to settings_organization_path, alert: "Billing isn't enabled for this organization."
  end
end
