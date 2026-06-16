require "test_helper"
require "rake"

class BillingRakeTest < ActiveSupport::TestCase
  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("tasks/billing", [ Rails.root.join("lib").to_s ])
    Rake::Task.define_task(:environment)
  end

  test "billing:grant credits an org by slug" do
    org = organizations(:riverside)
    org.update!(balance_microcents: 0)

    @rake["billing:grant"].invoke("riverside", "25", "cash")

    assert_equal Money.from_dollars(25), org.reload.balance_microcents
    assert_equal "grant", org.ledger_entries.recent_first.first.entry_type
  end
end
