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

    def fake? = false

    def valid_webhook?(url, params, signature)
      Twilio::Security::RequestValidator.new(@auth_token).validate(url, params, signature)
    end
  end
end
