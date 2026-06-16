require "test_helper"

class Settings::BillingControllerTest < ActionDispatch::IntegrationTest
  setup { @org = organizations(:riverside) }

  test "admin sees the billing page" do
    sign_in_as users(:one)
    @org.update!(balance_microcents: Money.from_dollars(12.5))
    get settings_billing_url
    assert_response :success
    assert_match "$12.50", response.body
  end

  test "non-admin is redirected" do
    sign_in_as users(:two)
    get settings_billing_url
    assert_redirected_to root_url
  end

  test "topup credits the balance" do
    sign_in_as users(:one)
    @org.update!(balance_microcents: 0)

    post topup_settings_billing_url, params: { amount: "20" }

    assert_redirected_to settings_billing_path
    assert_equal Money.from_dollars(20), @org.reload.balance_microcents
  end

  test "topup below minimum shows an error" do
    sign_in_as users(:one)
    post topup_settings_billing_url, params: { amount: "1" }
    assert_redirected_to settings_billing_path
    assert_equal flash[:alert], "Minimum top-up is $5."
  end

  test "add_payment_method redirects to checkout" do
    sign_in_as users(:one)
    post add_payment_method_settings_billing_url
    assert_response :redirect
    assert @org.reload.stripe_customer_id.present?
  end

  test "billing page is hidden when the feature flag is off" do
    sign_in_as users(:one)
    disable_billing_feature(@org)
    get settings_billing_url
    assert_redirected_to settings_organization_path
  end

  test "superadmin can grant credits" do
    sign_in_as users(:one) # superadmin in fixtures
    @org.update!(balance_microcents: 0)

    post grant_settings_billing_url, params: { amount: "50", note: "cash" }

    assert_redirected_to settings_billing_path
    assert_equal Money.from_dollars(50), @org.reload.balance_microcents
    assert_equal "grant", @org.ledger_entries.recent_first.first.entry_type
  end

  test "non-superadmin admin cannot grant credits" do
    users(:one).update!(superadmin: false)
    sign_in_as users(:one)
    @org.update!(balance_microcents: 0)

    post grant_settings_billing_url, params: { amount: "50" }

    assert_redirected_to root_url
    assert_equal 0, @org.reload.balance_microcents
  end
end
