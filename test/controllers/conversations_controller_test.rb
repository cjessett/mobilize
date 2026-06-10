require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  test "reply composes and delivers an outbound message" do
    sign_in_as users(:one)
    assert_enqueued_with(job: Message::DeliverJob) do
      post reply_conversation_url(people(:maria)), params: { message: { body: "Hi {{first_name}}" } }
    end
    message = people(:maria).messages.outbound.last
    assert_equal "Hi Maria", message.body
    assert_equal chapters(:north), message.chapter
  end

  test "cannot text someone who opted out" do
    people(:maria).update!(opted_out_sms_at: Time.current)
    sign_in_as users(:one)
    assert_no_difference "Message.count" do
      post reply_conversation_url(people(:maria)), params: { message: { body: "Hi" } }
    end
  end

  test "inbox lists conversations" do
    Message.compose!(person: people(:maria), body: "hello")
    sign_in_as users(:one)
    get conversations_url
    assert_response :success
    assert_match people(:maria).name, response.body
  end
end
