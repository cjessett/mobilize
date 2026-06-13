require "test_helper"

class Webhooks::TwilioControllerTest < ActionDispatch::IntegrationTest
  test "inbound sms creates a message" do
    assert_difference "Message.count" do
      post webhooks_twilio_inbound_sms_url, params: {
        To: chapters(:north).phone_number,
        From: people(:maria).phone,
        Body: "hello",
        MessageSid: "SM123"
      }
    end
    assert_response :success
  end

  test "rejects invalid signatures" do
    Sms.provider = Class.new do
      def valid_webhook?(*) = false
    end.new

    post webhooks_twilio_inbound_sms_url, params: { To: "x", From: "y", Body: "z" }
    assert_response :forbidden
  end

  test "status callback updates message status" do
    message = Message.compose!(person: people(:maria), body: "hi")
    message.update!(provider_sid: "SM999", status: "queued")

    post webhooks_twilio_sms_status_url, params: { MessageSid: "SM999", MessageStatus: "delivered" }
    assert_response :success
    assert_equal "delivered", message.reload.status
  end

  test "status callback charges the org for the message when billing is active" do
    organizations(:riverside).update!(stripe_customer_id: "cus_x", balance_microcents: Money.from_dollars(20))
    message = Message.compose!(person: people(:maria), body: "hi")
    message.update!(provider_sid: "SM777", status: "queued")

    post webhooks_twilio_sms_status_url, params: { MessageSid: "SM777", MessageStatus: "delivered", Price: "-0.00750" }

    assert_equal 750, message.reload.cost_microcents
    assert_equal Money.from_dollars(20) - 750, organizations(:riverside).reload.balance_microcents
  end
end
