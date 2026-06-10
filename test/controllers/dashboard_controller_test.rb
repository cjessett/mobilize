require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get root_url
    assert_redirected_to new_session_url
  end

  test "renders for a signed-in member" do
    sign_in_as users(:one)
    get root_url
    assert_response :success
    assert_match organizations(:riverside).name, response.body
  end
end
