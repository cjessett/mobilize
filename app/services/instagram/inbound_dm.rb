class Instagram::InboundDm
  def initialize(page_id:, sender_id:, message_text:, quick_reply_payload: nil)
    @page_id = page_id
    @sender_id = sender_id
    @message_text = message_text.to_s
    @quick_reply_payload = quick_reply_payload
  end

  def call
    organization = Organization.find_by(instagram_page_id: @page_id)
    return nil if organization.nil?

    person = organization.people.find_by(instagram_user_id: @sender_id)
    return nil if person.nil?

    param = @quick_reply_payload.presence || first_word

    Workflow.fire(
      trigger: "instagram_dm_received",
      person: person,
      param: param,
      payload: {
        message_text: @message_text,
        instagram_user_id: @sender_id
      }
    )

    person
  end

  private

  def first_word
    @message_text.strip.split(/\s+/).first.to_s.downcase.presence
  end
end
