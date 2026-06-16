module FeatureFlags
  # The whole chapter-billing + number-provisioning feature is gated on this.
  CHAPTER_BILLING = :chapter_billing

  class << self
    attr_writer :provider

    def provider
      @provider ||= build_provider
    end

    def configured?
      ENV["LAUNCHDARKLY_SDK_KEY"].present?
    end

    def enabled?(key, organization = nil)
      provider.enabled?(key.to_s, context_for(organization))
    end

    private

    def context_for(organization)
      if organization
        { key: "org-#{organization.id}", kind: "organization", name: organization.name }
      else
        { key: "anonymous", kind: "organization", name: "anonymous" }
      end
    end

    def build_provider
      configured? ? LaunchDarklyProvider.new(sdk_key: ENV["LAUNCHDARKLY_SDK_KEY"]) : FakeProvider.new
    end
  end
end
