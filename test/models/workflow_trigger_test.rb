require "test_helper"

class WorkflowTriggerTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @workflow = @org.workflows.create!(name: "Multi", access_scope: @org)
    @workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "hit" })
  end

  test "multiple triggers each enroll" do
    @workflow.workflow_triggers.create!(trigger: "form_submitted", param: "join")
    @workflow.workflow_triggers.create!(trigger: "donation_created")

    assert_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "donation_created", person: people(:maria))
    end
  end

  test "enrollment is once per person" do
    @workflow.workflow_triggers.create!(trigger: "donation_created")
    Workflow.fire(trigger: "donation_created", person: people(:maria))
    assert_no_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "donation_created", person: people(:maria))
    end
  end

  test "deleting the run allows re-enrollment" do
    @workflow.workflow_triggers.create!(trigger: "donation_created")
    perform_enqueued_jobs { Workflow.fire(trigger: "donation_created", person: people(:maria)) }
    @workflow.workflow_runs.find_by(person: people(:maria)).destroy

    assert_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "donation_created", person: people(:maria))
    end
  end

  test "incoming_text content filters" do
    contains = WorkflowTrigger.new(trigger: "incoming_text", config: { "match_type" => "contains", "value" => "yes" })
    assert contains.matches?(param: nil, payload: { body: "Oh YES please" })
    assert_not contains.matches?(param: nil, payload: { body: "no thanks" })

    exact = WorkflowTrigger.new(trigger: "incoming_text", config: { "match_type" => "exact", "value" => "STOP 2" })
    assert exact.matches?(param: nil, payload: { body: " stop 2 " })
    assert_not exact.matches?(param: nil, payload: { body: "stop" })

    regex = WorkflowTrigger.new(trigger: "incoming_text", config: { "match_type" => "regex", "value" => "\\b(yes|si)\\b" })
    assert regex.matches?(param: nil, payload: { body: "si claro" })
    assert_not regex.matches?(param: nil, payload: { body: "maybe" })
  end

  test "rsvp status filter" do
    trigger = WorkflowTrigger.new(trigger: "rsvp_created", config: { "status" => "yes" })
    assert trigger.matches?(param: nil, payload: { status: "yes" })
    assert_not trigger.matches?(param: nil, payload: { status: "waitlist" })
  end

  test "goal exits a running enrollment early" do
    @workflow.workflow_triggers.create!(trigger: "person_created")
    @workflow.update!(goal_trigger: "incoming_text")
    @workflow.workflow_steps.create!(position: 1, action: "wait", params: { "duration_minutes" => 60 })
    @workflow.workflow_steps.create!(position: 2, action: "add_tag", params: { "tag_name" => "finished" })

    Workflow.fire(trigger: "person_created", person: people(:maria))
    run = @workflow.workflow_runs.find_by(person: people(:maria))
    Workflow::RunStepJob.perform_now(run) # add_tag "hit"
    Workflow::RunStepJob.perform_now(run) # wait — re-enqueues

    Workflow.fire(trigger: "incoming_text", person: people(:maria), payload: { body: "yes!" })
    assert_equal "goal_met", run.reload.status
    assert_not_nil run.goal_achieved_at

    # The queued continuation is a no-op now.
    Workflow::RunStepJob.perform_now(run)
    assert_not_includes people(:maria).reload.tags.pluck(:name), "finished"
  end

  test "goal_param narrows the goal match" do
    @workflow.workflow_triggers.create!(trigger: "person_created")
    @workflow.update!(goal_trigger: "form_submitted", goal_param: "petition")
    Workflow.fire(trigger: "person_created", person: people(:maria))
    run = @workflow.workflow_runs.find_by(person: people(:maria))

    Workflow.fire(trigger: "form_submitted", person: people(:maria), param: "other-form")
    assert_equal "running", run.reload.status

    Workflow.fire(trigger: "form_submitted", person: people(:maria), param: "petition")
    assert_equal "goal_met", run.reload.status
  end

  test "step executions are recorded per step" do
    @workflow.workflow_triggers.create!(trigger: "person_created")
    perform_enqueued_jobs do
      Workflow.fire(trigger: "person_created", person: people(:maria))
    end
    run = @workflow.workflow_runs.last
    assert_equal "completed", run.status
    assert_equal 1, @workflow.workflow_step_executions.where(person: people(:maria)).count
  end
end
