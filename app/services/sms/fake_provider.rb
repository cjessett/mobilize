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

    # Area code "000" simulates an exhausted area code (no numbers available).
    def search_number(area_code:)
      return nil if area_code.to_s == "000"

      "+1#{area_code}#{rand(1_000_000..9_999_999)}"
    end

    def buy_number(phone_number:, sms_url: nil, status_url: nil)
      purchase = { phone_number: phone_number, sid: "PNFAKE#{SecureRandom.hex(12)}" }
      purchases << purchase
      purchase
    end

    def purchases
      @purchases ||= []
    end

    def fake? = true

    def valid_webhook?(_url, _params, _signature) = true
  end
end
