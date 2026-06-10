class EmailBlast::DeliverJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    return unless delivery.status == "pending"

    BlastMailer.blast(delivery).deliver_now
    delivery.update!(status: "sent")
    Activity.record!(person: delivery.person, kind: "email_sent", subject: delivery)
  rescue => e
    delivery.update!(status: "failed", error_message: e.message)
  end
end
