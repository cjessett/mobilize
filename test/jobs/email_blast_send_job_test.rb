require "test_helper"

class EmailBlastSendJobTest < ActiveJob::TestCase
  setup do
    @org = organizations(:riverside)
    @blast = @org.email_blasts.new(name: "Update", subject: "Hi {{first_name}}", access_scope: @org, status: "scheduled")
    @blast.body = "<div>Hello {{first_name}}!</div>"
    @blast.save!
  end

  test "delivers personalized email to people with email addresses" do
    assert_emails 1 do
      perform_enqueued_jobs { EmailBlast::SendJob.perform_now(@blast) }
    end

    assert_equal "sent", @blast.reload.status
    delivery = @blast.email_deliveries.find_by(person: people(:admin_person))
    assert_equal "sent", delivery.status

    email = ActionMailer::Base.deliveries.last
    assert_equal [ people(:admin_person).email ], email.to
    assert_equal "Hi Alex", email.subject
    assert_includes email.body.to_s, "Hello Alex!"
    assert_includes email.body.to_s, "Unsubscribe"
  end

  test "skips unsubscribed people" do
    people(:admin_person).update!(unsubscribed_email_at: Time.current)
    perform_enqueued_jobs { EmailBlast::SendJob.perform_now(@blast) }
    assert_empty @blast.email_deliveries
  end
end
