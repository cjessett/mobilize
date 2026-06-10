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
    Rails.application.config.x.sms_provider = Class.new do
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
end
