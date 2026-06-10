class Message::DeliverJob < ApplicationJob
  queue_as :default

  def perform(message)
    return unless message.status == "pending"
    return message.update!(status: "failed", error_message: "Person has opted out") if message.person.opted_out_sms?
    return message.update!(status: "failed", error_message: "Person has no phone number") if message.person.phone.blank?

    result = Sms.provider.send_message(
      to: message.person.phone,
      from: message.chapter&.phone_number,
      body: message.body
    )
    message.update!(status: result.status == "sent" ? "sent" : "queued", provider_sid: result.sid, sent_at: Time.current)
  rescue Sms::Error => e
    message.update!(status: "failed", error_message: e.message)
  end
end
