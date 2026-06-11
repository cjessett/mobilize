require "test_helper"

class BlastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @blast = organizations(:riverside).blasts.create!(
      name: "Rally reminder", body: "Hi {{first_name}}, rally Saturday!",
      access_scope: organizations(:riverside)
    )
  end

  test "clone creates a fresh draft copy" do
    @blast.update!(status: "sent", sent_at: Time.current)
    assert_difference "Blast.count" do
      post clone_blast_url(@blast)
    end
    copy = Blast.order(:id).last
    assert_equal "Rally reminder (copy)", copy.name
    assert_equal @blast.body, copy.body
    assert_equal "draft", copy.status
    assert_nil copy.sent_at
    assert_redirected_to edit_blast_url(copy)
  end

  test "test_send delivers a rendered test message without creating a Message" do
    assert_no_difference "Message.count" do
      post test_send_blast_url(@blast), params: { phone: "(555) 123-9999" }
    end
    delivery = fake_sms.deliveries.last
    assert_equal "+15551239999", delivery[:to]
    assert_no_match "{{", delivery[:body]
  end

  test "test_send rejects an invalid phone" do
    post test_send_blast_url(@blast), params: { phone: "abc" }
    assert_equal 0, fake_sms.deliveries.size
  end
end
