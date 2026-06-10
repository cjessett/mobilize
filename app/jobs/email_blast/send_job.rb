class EmailBlast::SendJob < ApplicationJob
  queue_as :default

  def perform(email_blast)
    return unless email_blast.status == "scheduled"

    email_blast.update!(status: "sending")
    seen_emails = Set.new
    email_blast.recipients.find_each do |person|
      next if seen_emails.include?(person.email)

      seen_emails << person.email
      delivery = email_blast.email_deliveries.create!(person: person)
      EmailBlast::DeliverJob.perform_later(delivery)
    end
    email_blast.update!(status: "sent", sent_at: Time.current)
  rescue => e
    email_blast.update!(status: "failed")
    raise e
  end
end
