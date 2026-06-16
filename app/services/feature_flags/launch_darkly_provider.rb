module FeatureFlags
  # Evaluates flags against LaunchDarkly. Only used when LAUNCHDARKLY_SDK_KEY is
  # set; otherwise FakeProvider stands in so the app runs offline.
  class LaunchDarklyProvider
    def initialize(sdk_key:)
      require "ldclient-rb"
      @client = LaunchDarkly::LDClient.new(sdk_key)
    end

    def enabled?(key, context)
      ld_context = LaunchDarkly::LDContext.create(
        key: context[:key],
        kind: context[:kind],
        name: context[:name]
      )
      @client.variation(key, ld_context, false)
    rescue StandardError => e
      Rails.logger.warn("[FeatureFlags] LaunchDarkly evaluation failed for #{key}: #{e.message}")
      false
    end

    def fake? = false
  end
end
