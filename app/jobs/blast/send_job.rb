class Blast::SendJob < ApplicationJob
  queue_as :default

  def perform(blast)
    return unless blast.status == "scheduled"

    blast.update!(status: "sending")
    seen_phones = Set.new
    blast.recipients.find_each do |person|
      next if seen_phones.include?(person.phone)

      seen_phones << person.phone
      Message.compose!(person: person, body: blast.body, blast: blast).deliver_later
    end
    blast.update!(status: "sent", sent_at: Time.current)
  rescue => e
    blast.update!(status: "failed")
    raise e
  end
end
