require "test_helper"

class ShortLinksControllerTest < ActionDispatch::IntegrationTest
  test "records click, activity, and workflow trigger, then redirects" do
    org = organizations(:riverside)
    blast = org.blasts.create!(name: "B", body: "x", access_scope: org)
    workflow = org.workflows.create!(name: "Clickers", trigger: "link_clicked", enabled: true, access_scope: org)
    workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "clicked" })
    link = ShortLink.create!(organization: org, blast: blast, person: people(:maria), destination_url: "https://example.org/x")

    assert_difference [ "LinkClick.count", "WorkflowRun.count" ] do
      get short_link_url(token: link.token)
    end
    assert_redirected_to "https://example.org/x"
    assert people(:maria).activities.exists?(kind: "link_clicked")
  end

  test "unknown token 404s" do
    get short_link_url(token: "missing12")
    assert_response :not_found
  end
end
