require "test_helper"

class WorkflowStepResolverTest < ActiveSupport::TestCase
  setup do
    travel_to Time.utc(2026, 6, 10, 17, 0) # inside texting hours
    @org = organizations(:riverside)
    @workflow = @org.workflows.create!(name: "Router test", access_scope: @org)
    @workflow.workflow_triggers.create!(trigger: "person_created")

    @north = @org.segments.create!(name: "North", access_scope: @org,
      definition: { "conditions" => [ { "type" => "chapter", "chapter_id" => chapters(:north).id } ] })
  end

  def build_router(mode:)
    router = @workflow.workflow_steps.create!(position: 0, action: "router", params: {
      "mode" => mode,
      "branches" => [
        { "name" => "North side", "segment_id" => @north.id.to_s },
        { "name" => "Else", "segment_id" => nil }
      ]
    })
    @workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "north-tag" }, parent_step: router, branch_index: 0)
    @workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "else-tag" }, parent_step: router, branch_index: 1)
    @workflow.workflow_steps.create!(position: 1, action: "add_tag", params: { "tag_name" => "after-router" })
    router
  end

  test "first_match runs only the first matching branch then continues" do
    build_router(mode: "first_match")
    perform_enqueued_jobs { Workflow.fire(trigger: "person_created", person: people(:maria)) }

    tags = people(:maria).reload.tags.pluck(:name)
    assert_includes tags, "north-tag" # maria is in North
    assert_not_includes tags, "else-tag"
    assert_includes tags, "after-router"
    assert_equal "completed", @workflow.workflow_runs.find_by(person: people(:maria)).status
  end

  test "first_match falls to the else branch when no segment matches" do
    build_router(mode: "first_match")
    perform_enqueued_jobs { Workflow.fire(trigger: "person_created", person: people(:admin_person)) }

    tags = people(:admin_person).reload.tags.pluck(:name)
    assert_not_includes tags, "north-tag"
    assert_includes tags, "else-tag"
    assert_includes tags, "after-router"
  end

  test "all_matches runs every matching branch in order" do
    build_router(mode: "all_matches")
    perform_enqueued_jobs { Workflow.fire(trigger: "person_created", person: people(:maria)) }

    tags = people(:maria).reload.tags.pluck(:name)
    assert_includes tags, "north-tag"
    assert_includes tags, "else-tag" # blank segment matches everyone
    assert_includes tags, "after-router"
  end

  test "router with no matching branches continues past it" do
    router = @workflow.workflow_steps.create!(position: 0, action: "router", params: {
      "mode" => "first_match",
      "branches" => [ { "name" => "North", "segment_id" => @north.id.to_s } ]
    })
    @workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "north-tag" }, parent_step: router, branch_index: 0)
    @workflow.workflow_steps.create!(position: 1, action: "add_tag", params: { "tag_name" => "after-router" })

    perform_enqueued_jobs { Workflow.fire(trigger: "person_created", person: people(:admin_person)) }
    tags = people(:admin_person).reload.tags.pluck(:name)
    assert_equal [ "after-router" ], tags & [ "north-tag", "after-router" ]
  end
end
