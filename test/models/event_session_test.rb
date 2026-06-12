require "test_helper"

class EventSessionTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @event = @org.events.create!(title: "Tenant school", starts_at: 3.days.from_now, ends_at: 3.days.from_now + 2.hours, access_scope: @org, capacity: 2)
  end

  test "creating an event creates a primary session mirroring its times" do
    session = @event.primary_session
    assert session.is_primary?
    assert_equal @event.starts_at, session.starts_at
    assert_equal @event.ends_at, session.ends_at
  end

  test "editing event times updates the primary session" do
    new_time = 5.days.from_now.change(usec: 0)
    @event.update!(starts_at: new_time)
    assert_equal new_time, @event.primary_session.reload.starts_at
    assert_equal 1, @event.event_sessions.count
  end

  test "rsvps attach to a session and dedupe per session" do
    extra = @event.event_sessions.create!(starts_at: 10.days.from_now)
    first = @event.rsvp_for!(people(:maria))
    assert_equal @event.primary_session, first.event_session

    assert_no_difference "Rsvp.count" do
      @event.rsvp_for!(people(:maria))
    end
    assert_difference "Rsvp.count" do
      @event.rsvp_for!(people(:maria), session: extra)
    end
  end

  test "capacity waitlists per session" do
    extra = @event.event_sessions.create!(starts_at: 10.days.from_now)
    @event.rsvp_for!(people(:maria))
    @event.rsvp_for!(people(:admin_person))
    late = @org.people.create!(first_name: "Late", phone: "+15553334444")
    assert_equal "waitlist", @event.rsvp_for!(late).status
    assert_equal "yes", @event.rsvp_for!(late, session: extra).status
  end

  test "yes/no/maybe statuses and changing your answer" do
    rsvp = @event.rsvp_for!(people(:maria), status: "maybe")
    assert_equal "maybe", rsvp.status
    @event.rsvp_for!(people(:maria), status: "yes")
    assert_equal "yes", rsvp.reload.status
  end

  test "recurring events generate sessions to the horizon" do
    @event.update!(recurrence_frequency: "weekly", recurrence_days_ahead: 30)
    perform_enqueued_jobs(only: Event::GenerateSessionsJob) { Event::GenerateSessionsJob.perform_now(@event) }
    counts = @event.event_sessions.count
    assert_includes 4..6, counts # ~30 days of weekly sessions after the first
    assert @event.event_sessions.maximum(:starts_at) <= Time.current + 31.days
  end

  test "recurrence respects the until date" do
    @event.update!(recurrence_frequency: "daily", recurrence_days_ahead: 30, recurrence_until: 5.days.from_now.to_date)
    Event::GenerateSessionsJob.perform_now(@event)
    assert @event.event_sessions.maximum(:starts_at) <= 5.days.from_now.end_of_day
    assert @event.event_sessions.count.between?(2, 4)
  end

  test "check_in! records activity and fires event_attended" do
    workflow = @org.workflows.create!(name: "Attended", access_scope: @org)
    workflow.workflow_triggers.create!(trigger: "event_attended")
    workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "showed-up" })

    rsvp = @event.rsvp_for!(people(:maria))
    assert_difference "WorkflowRun.count" do
      @event.check_in!(rsvp)
    end
    assert rsvp.reload.attended?
  end

  test "confirmation job asks unconfirmed yes RSVPs" do
    travel_to Time.utc(2026, 6, 10, 17, 0) do
      @event.update!(confirmation_days_before: 2, starts_at: 3.days.from_now)
      rsvp = @event.rsvp_for!(people(:maria))
      session = @event.primary_session.reload

      assert_difference "Message.count" do
        Event::ConfirmationJob.perform_now(session, session.starts_at.to_i)
      end
      assert_match "confirm", people(:maria).messages.outbound.last.body

      rsvp.confirm!
      assert_no_difference "Message.count" do
        Event::ConfirmationJob.perform_now(session, session.starts_at.to_i)
      end
    end
  end

  test "ics payload includes each session" do
    @event.event_sessions.create!(starts_at: 10.days.from_now, title: "Week two")
    ics = IcsCalendar.for_event(@event)
    assert_equal 2, ics.scan("BEGIN:VEVENT").size
    assert_includes ics, "SUMMARY:Tenant school"
    assert_includes ics, "Week two"
  end
end
