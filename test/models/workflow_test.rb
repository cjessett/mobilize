require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @workflow = @org.workflows.create!(name: "Welcome", trigger: "keyword_received", trigger_param: "join", access_scope: @org)
    @workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "joined" })
    @workflow.workflow_steps.create!(position: 1, action: "send_sms", params: { "body" => "Welcome {{first_name}}!" })
  end

  test "fire creates a run for matching trigger and param" do
    assert_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "keyword_received", person: people(:maria), param: "join")
    end
  end

  test "fire skips mismatched params and disabled workflows" do
    assert_no_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "keyword_received", person: people(:maria), param: "other")
    end

    @workflow.update!(enabled: false)
    assert_no_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "keyword_received", person: people(:maria), param: "join")
    end
  end

  test "blank trigger_param matches any param" do
    @workflow.update!(trigger_param: nil)
    assert_difference "WorkflowRun.count" do
      Workflow.fire(trigger: "keyword_received", person: people(:maria), param: "anything")
    end
  end

  test "run executes steps in order and completes" do
    perform_enqueued_jobs do
      Workflow.fire(trigger: "keyword_received", person: people(:maria), param: "join")
    end

    run = @workflow.workflow_runs.last
    assert_equal "completed", run.status
    assert_includes people(:maria).reload.tags.pluck(:name), "joined"
    assert_equal "Welcome Maria!", people(:maria).messages.outbound.last.body
  end

  test "wait steps re-enqueue with a delay" do
    @workflow.workflow_steps.create!(position: 2, action: "wait", params: { "duration_minutes" => 10 })
    @workflow.workflow_steps.create!(position: 3, action: "add_tag", params: { "tag_name" => "waited" })

    run = @workflow.workflow_runs.create!(person: people(:maria))
    Workflow::RunStepJob.perform_now(run) # add_tag
    Workflow::RunStepJob.perform_now(run) # send_sms
    assert_enqueued_with(job: Workflow::RunStepJob) do
      Workflow::RunStepJob.perform_now(run) # wait step schedules the next job
    end
    assert_equal "running", run.reload.status
    assert_equal 3, run.current_position
  end
end
