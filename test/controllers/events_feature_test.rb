require "test_helper"

class EventsFeatureTest < ActionDispatch::IntegrationTest
  setup do
    @org = organizations(:riverside)
    @event = @org.events.create!(title: "Rally", starts_at: 3.days.from_now, access_scope: @org)
  end

  test "clone copies the event as a draft copy" do
    sign_in_as users(:one)
    assert_difference "Event.count" do
      post clone_event_url(@event)
    end
    assert Event.exists?(title: "Rally (copy)")
  end

  test "public rsvp accepts a status and session" do
    extra = @event.event_sessions.create!(starts_at: 10.days.from_now)
    post rsvp_public_event_url(@org.slug, @event), params: {
      first_name: "Sam", phone: "555-888-7777", status: "maybe", session_id: extra.id
    }
    rsvp = @event.rsvps.last
    assert_equal "maybe", rsvp.status
    assert_equal extra, rsvp.event_session
  end

  test "unlisted and unapproved events are hidden from the public index but unlisted is reachable" do
    @event.update!(unlisted: true)
    get public_events_url(@org.slug)
    assert_no_match @event.title, response.body
    get public_event_url(@org.slug, @event)
    assert_response :success

    @event.update!(approved: false)
    get public_event_url(@org.slug, @event)
    assert_response :not_found
  end

  test "calendar feed and per-event ics render" do
    get calendar_feed_url(@org.slug)
    assert_response :success
    assert_match "BEGIN:VCALENDAR", response.body
    assert_match @event.title, response.body

    get calendar_public_event_url(@org.slug, @event)
    assert_match "BEGIN:VEVENT", response.body
  end

  test "host tools shows rsvps and checks people in without login" do
    rsvp = @event.rsvp_for!(people(:maria))
    token = @event.host_token!

    get host_tools_url(token: token)
    assert_response :success
    assert_match people(:maria).name, response.body

    post host_tools_check_in_url(token: token, rsvp_id: rsvp.id)
    assert rsvp.reload.attended?
  end

  test "rsvp confirmation link confirms" do
    rsvp = @event.rsvp_for!(people(:maria))
    get rsvp_confirmation_url(token: rsvp.generate_token_for(:confirmation))
    assert_response :success
    assert_not_nil rsvp.reload.confirmed_at
  end

  test "supporters can submit events that await approval" do
    post public_host_an_event_url(@org.slug), params: {
      title: "Block party", starts_at: 2.weeks.from_now.strftime("%Y-%m-%d %H:%M"),
      first_name: "Hostess", email: "hostess@example.com"
    }
    event = Event.order(:id).last
    assert_not event.approved?
    assert event.unlisted?
    assert_equal "hostess@example.com", event.submitted_by.email

    sign_in_as users(:one)
    assert_emails 1 do
      post approve_event_url(event)
    end
    assert event.reload.approved?
  end

  test "co-host code shares the event with another organization" do
    code = @event.cohost_code!
    other_admin = User.create!(email_address: "other@example.com", password: "password")
    other_admin.memberships.create!(organization: organizations(:other_org), role: "admin", access_scope: organizations(:other_org))
    sign_in_as other_admin

    post redeem_cohost_events_url, params: { code: code }
    assert @event.co_host_organizations.include?(organizations(:other_org))
    get event_url(@event)
    assert_response :success
  end

  test "attendance webhook marks people attended" do
    token = @org.webhook_token!
    post webhooks_attendance_url(token: token), params: {
      event_id: @event.id, phone: "555-123-0002"
    }, as: :json
    assert_response :success
    assert @event.rsvps.find_by(person: people(:maria)).attended?
  end
end
