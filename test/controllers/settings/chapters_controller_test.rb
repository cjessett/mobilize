require "test_helper"

class Settings::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test "admin can create a chapter with zip coverage" do
    sign_in_as users(:one)
    assert_difference "Chapter.count" do
      post settings_chapters_url, params: { chapter: { name: "South Side", phone_number: "555-000-3333", zip_codes_list: "60615, 60637" } }
    end
    chapter = Chapter.find_by(name: "South Side")
    assert_equal "+15550003333", chapter.phone_number
    assert_equal %w[60615 60637], chapter.zip_codes_list
  end

  test "non-admin cannot manage chapters" do
    sign_in_as users(:two)
    get settings_chapters_url
    assert_redirected_to root_url
  end

  test "default chapter cannot be deleted" do
    sign_in_as users(:one)
    assert_no_difference "Chapter.count" do
      delete settings_chapter_url(chapters(:main))
    end
  end
end
