module Sms
  Result = Struct.new(:sid, :status, keyword_init: true)
  Error = Class.new(StandardError)

  class << self
    attr_writer :provider

    def provider
      @provider ||= build_provider
    end

    private

    def build_provider
      if ENV["TWILIO_ACCOUNT_SID"].present? && ENV["TWILIO_AUTH_TOKEN"].present?
        TwilioProvider.new(account_sid: ENV["TWILIO_ACCOUNT_SID"], auth_token: ENV["TWILIO_AUTH_TOKEN"], default_from: ENV["TWILIO_FROM_NUMBER"])
      else
        FakeProvider.new
      end
    end
  end
end
