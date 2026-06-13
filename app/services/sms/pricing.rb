module Sms
  # Estimates SMS cost when Twilio has not (yet) reported a real price.
  # The real charge always comes from Twilio's status callback; this is the
  # fallback used for the pre-send balance check and for messages whose
  # price never arrives.
  module Pricing
    module_function

    # Fallback price per segment, in microcents. Default ~$0.0079 (US long code).
    def per_segment_microcents
      ENV.fetch("TWILIO_SMS_PRICE_MICROCENTS", "790").to_i
    end

    # Rough GSM-7 vs UCS-2 segment count.
    def segments(body)
      text = body.to_s
      return 1 if text.empty?

      ascii = text.ascii_only?
      single_limit = ascii ? 160 : 70
      multi_limit = ascii ? 153 : 67
      text.length <= single_limit ? 1 : (text.length.to_f / multi_limit).ceil
    end

    def estimate_microcents(body)
      segments(body) * per_segment_microcents
    end
  end
end
