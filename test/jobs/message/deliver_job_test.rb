require "test_helper"

class Message::DeliverJobTest < ActiveJob::TestCase
  setup { @org = organizations(:riverside) }

  test "delivers when balance is available" do
    @org.update!(stripe_customer_id: "cus_x", balance_microcents: Money.from_dollars(20))
    message = Message.compose!(person: people(:maria), body: "hi")

    Message::DeliverJob.perform_now(message)

    assert_includes %w[sent queued], message.reload.status
  end

  test "blocks delivery when billing is active but balance is exhausted" do
    @org.update!(stripe_customer_id: "cus_x", balance_microcents: 0)
    message = Message.compose!(person: people(:maria), body: "hi")

    Message::DeliverJob.perform_now(message)

    message.reload
    assert_equal "failed", message.status
    assert_match(/Insufficient balance/, message.error_message)
    assert_empty fake_sms.deliveries
  end

  test "does not gate orgs without billing" do
    message = Message.compose!(person: people(:maria), body: "hi")
    Message::DeliverJob.perform_now(message)
    assert_includes %w[sent queued], message.reload.status
  end
end
