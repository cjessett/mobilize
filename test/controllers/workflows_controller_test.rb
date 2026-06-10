require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  test "create workflow with steps" do
    sign_in_as users(:one)
    assert_difference "Workflow.count" do
      post workflows_url, params: {
        workflow: {
          name: "Tag follow-up",
          trigger: "tag_added",
          trigger_param: "member",
          access_scope_gid: "organization",
          steps: [
            { action: "send_sms", body: "Thanks {{first_name}}" },
            { action: "wait", duration_minutes: "30" },
            { action: "notify_member", email: users(:one).email_address }
          ]
        }
      }
    end
    workflow = Workflow.find_by(name: "Tag follow-up")
    assert_equal %w[send_sms wait notify_member], workflow.workflow_steps.map(&:action)
    assert_equal({ "body" => "Thanks {{first_name}}" }, workflow.workflow_steps.first.params)
  end

  test "tag_added trigger fires workflow when person is tagged" do
    org = organizations(:riverside)
    workflow = org.workflows.create!(name: "W", trigger: "tag_added", trigger_param: "vip", access_scope: org)
    workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "vip-followed-up" })

    assert_difference "WorkflowRun.count" do
      people(:maria).update!(tag_list: "vip")
    end
  end
end
