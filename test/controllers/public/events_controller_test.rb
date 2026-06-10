require "test_helper"

class Public::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = organizations(:riverside)
    @event = @org.events.create!(title: "Rally", starts_at: 3.days.from_now, access_scope: @org)
  end

  test "public event page renders without auth" do
    get public_event_url(@org.slug, @event)
    assert_response :success
    assert_match @event.title, response.body
  end

  test "rsvp creates person by zip-assigned chapter and rsvp" do
    assert_difference [ "Person.count", "Rsvp.count" ] do
      post rsvp_public_event_url(@org.slug, @event), params: {
        first_name: "Pat", phone: "555-777-8888", zip_code: "60601"
      }
    end
    person = @org.people.find_by(phone: "+15557778888")
    assert_equal chapters(:north), person.primary_chapter
    assert_equal "yes", @event.rsvps.find_by(person: person).status
  end

  test "rsvp matches existing person by phone" do
    assert_no_difference "Person.count" do
      post rsvp_public_event_url(@org.slug, @event), params: { first_name: "Maria", phone: people(:maria).phone }
    end
    assert @event.rsvps.exists?(person: people(:maria))
  end

  test "rsvp requires phone or email" do
    assert_no_difference "Rsvp.count" do
      post rsvp_public_event_url(@org.slug, @event), params: { first_name: "Nobody" }
    end
  end
end
