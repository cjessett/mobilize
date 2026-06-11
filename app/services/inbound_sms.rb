require "open-uri"

# Processes an inbound SMS webhook: finds/creates the person, records the
# message, handles opt-out keywords and org keywords.
class InboundSms
  OPT_OUT_WORDS = %w[stop stopall unsubscribe cancel end quit].freeze
  OPT_IN_WORDS = %w[start unstop yes].freeze

  def initialize(to:, from:, body:, provider_sid: nil, media: [])
    @to = PhoneNumber.normalize(to)
    @from = PhoneNumber.normalize(from)
    @body = body.to_s
    @provider_sid = provider_sid
    @media = media
  end

  def call
    chapter = Chapter.find_by(phone_number: @to)
    return nil if chapter.nil?

    organization = chapter.organization
    person = organization.people.find_by(phone: @from) ||
      organization.people.create!(phone: @from, zip_code: nil).tap { |p| p.assign_primary_chapter(chapter: chapter) }

    message = Message.create!(
      organization: organization,
      person: person,
      chapter: chapter,
      direction: "inbound",
      body: @body,
      status: "received",
      provider_sid: @provider_sid
    )

    attach_media(message)
    handle_opt_keywords(person)
    if (keyword = Keyword.match(organization, @body))
      keyword.apply!(person)
      Workflow.fire(trigger: "keyword_received", person: person, param: keyword.word)
    end
    Workflow.fire(trigger: "incoming_text", person: person, payload: { body: @body })

    message
  end

  private

  # Twilio media URLs require basic auth with the account credentials.
  # A failed download shouldn't fail the whole webhook.
  def attach_media(message)
    @media.each_with_index do |item, index|
      next if item[:url].blank?

      options = {}
      if ENV["TWILIO_ACCOUNT_SID"].present?
        options[:http_basic_authentication] = [ ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"] ]
      end
      extension = item[:content_type].to_s.split("/").last.presence || "bin"
      message.media.attach(
        io: URI.open(item[:url], **options),
        filename: "mms-#{message.id}-#{index}.#{extension}",
        content_type: item[:content_type]
      )
    rescue OpenURI::HTTPError, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.warn("[InboundSms] failed to fetch media #{item[:url]}: #{e.message}")
    end
  end

  def handle_opt_keywords(person)
    first_word = @body.strip.split(/\s+/).first.to_s.downcase
    if OPT_OUT_WORDS.include?(first_word)
      person.update!(opted_out_sms_at: Time.current)
    elsif OPT_IN_WORDS.include?(first_word) && person.opted_out_sms?
      person.update!(opted_out_sms_at: nil)
    end
  end
end
