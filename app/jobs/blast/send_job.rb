class Blast::SendJob < ApplicationJob
  queue_as :default

  def perform(blast)
    return unless blast.status == "scheduled"

    blast.update!(status: "sending")
    seen_phones = Set.new
    blast.recipients.find_each do |person|
      next if seen_phones.include?(person.phone)

      seen_phones << person.phone
      body = blast.body_for(person.preferred_language)
      if blast.texting_hours_mode == "skip" && DeliveryWindow.next_allowed_time(person: person, organization: blast.organization)
        message = Message.compose!(person: person, body: body, blast: blast)
        message.update!(status: "failed", error_message: "Outside texting hours")
        next
      end

      message = Message.compose!(
        person: person, body: body, blast: blast, media: blast.media.blobs,
        respect_texting_hours: blast.texting_hours_mode == "queue"
      )
      message.deliver_later
    end
    blast.update!(status: "sent", sent_at: Time.current)
  rescue => e
    blast.update!(status: "failed")
    raise e
  end
end
