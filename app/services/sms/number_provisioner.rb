module Sms
  # Provisions a Twilio number for a chapter given only an area code: finds an
  # available SMS-capable number, buys it, wires its webhooks, and saves it.
  class NumberProvisioner
    # Approx Twilio monthly cost of a US local number, charged once on
    # provisioning when the org has billing active.
    NUMBER_PRICE_MICROCENTS = ENV.fetch("TWILIO_NUMBER_PRICE_MICROCENTS", "115000").to_i

    def initialize(chapter)
      @chapter = chapter
    end

    def call(area_code:)
      area_code = area_code.to_s.strip
      raise Error, "Enter a 3-digit area code." unless area_code.match?(/\A\d{3}\z/)

      number = Sms.provider.search_number(area_code: area_code)
      raise Error, "No numbers available for area code #{area_code}. Try a nearby area code." if number.blank?

      result = Sms.provider.buy_number(phone_number: number, sms_url: inbound_url, status_url: status_url)
      @chapter.update!(phone_number: result[:phone_number], twilio_sid: result[:sid], provisioned_at: Time.current)
      charge_for_number
      result
    end

    private

    def charge_for_number
      org = @chapter.organization
      return unless org.billing_active?

      org.record_ledger_entry!(
        entry_type: "charge",
        amount_microcents: -NUMBER_PRICE_MICROCENTS,
        description: "Phone number #{@chapter.phone_number} (#{@chapter.name})"
      )
    end

    def inbound_url = absolute_url(:webhooks_twilio_inbound_sms_url)
    def status_url = absolute_url(:webhooks_twilio_sms_status_url)

    # Webhooks need a publicly reachable host; without one we still buy the
    # number but leave Twilio's webhooks unset (set later or in the console).
    def absolute_url(helper)
      return nil if Rails.application.routes.default_url_options[:host].blank?

      Rails.application.routes.url_helpers.public_send(helper)
    end
  end
end
