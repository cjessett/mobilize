class Message::DeliverJob < ApplicationJob
  queue_as :default

  def perform(message)
    return unless message.status == "pending"
    if message.send_after&.future?
      Message::DeliverJob.set(wait_until: message.send_after).perform_later(message)
      return
    end
    return message.update!(status: "failed", error_message: "Person has opted out") if message.person.opted_out_sms?
    return message.update!(status: "failed", error_message: "Person has no phone number") if message.person.phone.blank?
    return message.update!(status: "failed", error_message: "Insufficient balance — add funds to keep texting") if message.organization.sms_blocked?

    result = Sms.provider.send_message(
      to: message.person.phone,
      from: message.chapter&.phone_number,
      body: message.body,
      media_urls: media_urls(message),
      status_callback: status_callback_url
    )
    message.update!(status: result.status == "sent" ? "sent" : "queued", provider_sid: result.sid, sent_at: Time.current)
  rescue Sms::Error => e
    message.update!(status: "failed", error_message: e.message)
  end

  private

  # Media and status callbacks need a publicly reachable host; without one
  # the message still sends as plain SMS with no callback.
  def media_urls(message)
    return [] unless message.media.attached? && default_host.present?

    message.media.map { |attachment| Rails.application.routes.url_helpers.rails_blob_url(attachment) }
  end

  def status_callback_url
    return nil if default_host.blank?

    Rails.application.routes.url_helpers.webhooks_twilio_sms_status_url
  end

  def default_host
    Rails.application.routes.default_url_options[:host]
  end
end
