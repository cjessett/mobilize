require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @event = @org.events.create!(title: "Rally", starts_at: 3.days.from_now, access_scope: @org, capacity: 2)
  end

  test "rsvp_for! creates RSVP, records activity, fires workflow" do
    workflow = @org.workflows.create!(name: "W", trigger: "rsvp_created", access_scope: @org)
    workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "rsvped" })

    assert_difference [ "Rsvp.count", "WorkflowRun.count" ] do
      @event.rsvp_for!(people(:maria))
    end
    assert_equal "rsvp_created", people(:maria).activities.recent_first.first.kind
  end

  test "rsvp_for! is idempotent per person" do
    @event.rsvp_for!(people(:maria))
    assert_no_difference "Rsvp.count" do
      @event.rsvp_for!(people(:maria))
    end
  end

  test "waitlists when at capacity" do
    @event.rsvp_for!(people(:maria))
    @event.rsvp_for!(people(:admin_person))
    extra = @org.people.create!(first_name: "Late", phone: "+15553334444")
    assert_equal "waitlist", @event.rsvp_for!(extra).status
  end

  test "creating a future event schedules a reminder" do
    assert_enqueued_with(job: Event::ReminderJob) do
      @org.events.create!(title: "Meeting", starts_at: 3.days.from_now, access_scope: @org)
    end
  end

  test "reminder texts yes RSVPs and skips stale schedules" do
    @event.rsvp_for!(people(:maria))
    session = @event.primary_session

    assert_no_difference "Message.count" do
      Event::ReminderJob.perform_now(session, (session.starts_at - 1.hour).to_i)
    end

    assert_difference "Message.count" do
      Event::ReminderJob.perform_now(session, session.starts_at.to_i)
    end
    assert_match @event.title, people(:maria).messages.outbound.last.body
  end
end
