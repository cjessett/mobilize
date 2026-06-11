require "test_helper"

class Webhooks::DonationsControllerTest < ActionDispatch::IntegrationTest
  test "creates a donation and upserts the person" do
    token = organizations(:riverside).webhook_token!
    assert_difference [ "Donation.count", "Person.count" ] do
      post webhooks_donations_url(token: token), params: {
        phone: "(555) 777-8888", first_name: "Dana", amount_cents: 1500, source: "actblue"
      }, as: :json
    end
    assert_response :created
    donation = Donation.order(:id).last
    assert_equal "+15557778888", donation.person.phone
    assert_equal 1500, donation.amount_cents
  end

  test "rejects an unknown token" do
    post webhooks_donations_url(token: "nope"), params: { phone: "5557778888", amount_cents: 100 }, as: :json
    assert_response :forbidden
  end

  test "rejects a payload without phone or email" do
    token = organizations(:riverside).webhook_token!
    post webhooks_donations_url(token: token), params: { amount_cents: 100 }, as: :json
    assert_response :unprocessable_entity
  end
end
