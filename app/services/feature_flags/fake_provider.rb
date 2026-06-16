module FeatureFlags
  # Offline stand-in for LaunchDarkly. Defaults flags on everywhere except
  # production (where an unconfigured flag service should fail closed), and
  # lets tests toggle individual flags per organization.
  class FakeProvider
    def initialize(default: !Rails.env.production?)
      @default = default
      @overrides = {}
    end

    def enabled?(key, context)
      @overrides.fetch([ key.to_s, context[:key] ]) { @overrides.fetch([ key.to_s, :all ], @default) }
    end

    # Override a flag, optionally scoped to one organization.
    def set(key, enabled, organization: nil)
      scope = organization ? "org-#{organization.id}" : :all
      @overrides[[ key.to_s, scope ]] = enabled
    end

    def fake? = true
  end
end
