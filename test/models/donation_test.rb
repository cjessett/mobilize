require "test_helper"

class DonationTest < ActiveSupport::TestCase
  test "records activity and fires donation_created workflows" do
    workflow = organizations(:riverside).workflows.create!(
      name: "Thank donors", trigger: "donation_created", enabled: true,
      access_scope: organizations(:riverside)
    )
    workflow.workflow_steps.create!(position: 0, action: "send_sms", params: { "body" => "Thanks {{first_name}}!" })

    donation = nil
    assert_difference "WorkflowRun.count" do
      donation = organizations(:riverside).donations.create!(person: people(:maria), amount_cents: 2500, source: "spring-fund")
    end
    assert people(:maria).activities.exists?(kind: "donation_created", subject: donation)
    assert_equal 25.0, donation.amount
  end
end
