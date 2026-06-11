module Sms
  # Used in development and test when no Twilio credentials are configured.
  # Records every send so the app is fully demoable without an account.
  class FakeProvider
    attr_reader :deliveries

    def initialize
      @deliveries = []
    end

    def send_message(to:, body:, from: nil, media_urls: [], status_callback: nil)
      delivery = { to: to, from: from, body: body, media_urls: media_urls, sid: "FAKE#{SecureRandom.hex(16)}" }
      @deliveries << delivery
      Rails.logger.info("[FakeSms] to=#{to} from=#{from} media=#{media_urls.size} body=#{body.truncate(120)}")
      Result.new(sid: delivery[:sid], status: "sent")
    end

    def fake? = true

    def valid_webhook?(_url, _params, _signature) = true
  end
end
