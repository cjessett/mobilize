module Billing
  # Lazily creates (and memoizes) the org's Stripe customer.
  class CustomerSetup
    def initialize(organization)
      @organization = organization
    end

    def call
      return @organization.stripe_customer_id if @organization.stripe_customer_id.present?

      customer_id = Billing.provider.create_customer(name: @organization.name, metadata: { organization_id: @organization.id })
      @organization.update!(stripe_customer_id: customer_id)
      customer_id
    end
  end
end
