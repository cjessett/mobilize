# Processes an inbound SMS webhook: finds/creates the person, records the
# message, handles opt-out keywords and org keywords.
class InboundSms
  OPT_OUT_WORDS = %w[stop stopall unsubscribe cancel end quit].freeze
  OPT_IN_WORDS = %w[start unstop yes].freeze

  def initialize(to:, from:, body:, provider_sid: nil)
    @to = PhoneNumber.normalize(to)
    @from = PhoneNumber.normalize(from)
    @body = body.to_s
    @provider_sid = provider_sid
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

    handle_opt_keywords(person)
    if (keyword = Keyword.match(organization, @body))
      keyword.apply!(person)
      Workflow.fire(trigger: "keyword_received", person: person, param: keyword.word)
    end

    message
  end

  private

  def handle_opt_keywords(person)
    first_word = @body.strip.split(/\s+/).first.to_s.downcase
    if OPT_OUT_WORDS.include?(first_word)
      person.update!(opted_out_sms_at: Time.current)
    elsif OPT_IN_WORDS.include?(first_word) && person.opted_out_sms?
      person.update!(opted_out_sms_at: nil)
    end
  end
end
