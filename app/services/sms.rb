module Sms
  Result = Struct.new(:sid, :status, keyword_init: true)
  Error = Class.new(StandardError)

  def self.provider
    Rails.application.config.x.sms_provider ||= build_provider
  end

  def self.build_provider
    if ENV["TWILIO_ACCOUNT_SID"].present? && ENV["TWILIO_AUTH_TOKEN"].present?
      TwilioProvider.new(account_sid: ENV["TWILIO_ACCOUNT_SID"], auth_token: ENV["TWILIO_AUTH_TOKEN"], default_from: ENV["TWILIO_FROM_NUMBER"])
    else
      FakeProvider.new
    end
  end
end
