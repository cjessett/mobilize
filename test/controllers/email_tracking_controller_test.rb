require "test_helper"

class EmailTrackingControllerTest < ActionDispatch::IntegrationTest
  setup do
    org = organizations(:riverside)
    @blast = org.email_blasts.new(name: "B", subject: "S", access_scope: org, status: "sent")
    @blast.body = "<p>hi</p>"
    @blast.save!
    @delivery = @blast.email_deliveries.create!(person: people(:admin_person), status: "sent")
  end

  test "open tracking pixel marks delivery opened" do
    get email_open_url(token: @delivery.generate_token_for(:open_tracking))
    assert_response :success
    assert @delivery.reload.opened_at.present?
  end

  test "unsubscribe link unsubscribes the person" do
    get unsubscribe_url(token: people(:admin_person).generate_token_for(:unsubscribe))
    assert_response :success
    assert people(:admin_person).reload.unsubscribed_email?
  end

  test "invalid unsubscribe token is a 404" do
    get unsubscribe_url(token: "bogus")
    assert_response :not_found
  end
end
