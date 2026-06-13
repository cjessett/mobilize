module Sms
  class TwilioProvider
    def initialize(account_sid:, auth_token:, default_from: nil)
      @client = Twilio::REST::Client.new(account_sid, auth_token)
      @auth_token = auth_token
      @default_from = default_from
    end

    def send_message(to:, body:, from: nil, media_urls: [], status_callback: nil)
      message = @client.messages.create(
        to: to,
        from: from.presence || @default_from,
        body: body,
        media_url: media_urls.presence,
        status_callback: status_callback
      )
      Result.new(sid: message.sid, status: message.status)
    rescue Twilio::REST::RestError => e
      raise Error, e.message
    end

    # Returns the first available SMS-capable local number in an area code,
    # or nil when none are available.
    def search_number(area_code:)
      numbers = @client.available_phone_numbers("US").local.list(area_code: area_code, sms_enabled: true, limit: 1)
      numbers.first&.phone_number
    rescue Twilio::REST::RestError => e
      raise Error, e.message
    end

    def buy_number(phone_number:, sms_url: nil, status_url: nil)
      record = @client.incoming_phone_numbers.create(
        phone_number: phone_number,
        sms_url: sms_url,
        sms_method: "POST",
        status_callback: status_url,
        status_callback_method: "POST"
      )
      { phone_number: record.phone_number, sid: record.sid }
    rescue Twilio::REST::RestError => e
      raise Error, e.message
    end

    def fake? = false

    def valid_webhook?(url, params, signature)
      Twilio::Security::RequestValidator.new(@auth_token).validate(url, params, signature)
    end
  end
end
