module Billing
  # Tops the balance back up when it dips below the org's configured threshold,
  # so sending isn't interrupted. No-op unless the org opted in.
  class AutoRecharge
    def initialize(organization)
      @organization = organization
    end

    def call
      return unless @organization.auto_recharge_enabled?
      return if @organization.auto_recharge_threshold_microcents.blank?
      return if @organization.balance_microcents > @organization.auto_recharge_threshold_microcents

      dollars = Money.to_dollars(@organization.auto_recharge_amount_microcents.to_i)
      Topup.new(@organization, dollars: dollars).call
    rescue Error => e
      Rails.logger.warn("[AutoRecharge] org=#{@organization.id} failed: #{e.message}")
    end
  end
end
