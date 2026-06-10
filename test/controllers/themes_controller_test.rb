require "test_helper"

class ThemesControllerTest < ActionDispatch::IntegrationTest
  test "switches theme via cookie" do
    patch theme_url, params: { theme: "light" }
    assert_equal "light", cookies[:theme]

    patch theme_url, params: { theme: "dark" }
    assert_equal "dark", cookies[:theme]
  end

  test "unknown values fall back to dark" do
    patch theme_url, params: { theme: "hotdog" }
    assert_equal "dark", cookies[:theme]
  end

  test "light theme renders without dark class" do
    sign_in_as users(:one)
    patch theme_url, params: { theme: "light" }
    get root_url
    assert_select "html:not(.dark)"

    patch theme_url, params: { theme: "dark" }
    get root_url
    assert_select "html.dark"
  end
end
