require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "org-wide member sees all people" do
    sign_in_as users(:one)
    get people_url
    assert_response :success
    assert_match people(:maria).name, response.body
    assert_match people(:admin_person).name, response.body
  end

  test "chapter-scoped member only sees their chapter's people" do
    sign_in_as users(:two)
    get people_url
    assert_response :success
    assert_match people(:maria).name, response.body
    assert_no_match people(:admin_person).first_name, response.body
  end

  test "create person with tags" do
    sign_in_as users(:one)
    assert_difference "Person.count" do
      post people_url, params: { person: { first_name: "Tagged", phone: "555-222-0001", tag_list: "volunteer" } }
    end
    person = Person.find_by(phone: "+15552220001")
    assert_equal [ "volunteer" ], person.tags.pluck(:name)
  end

  test "chapter-scoped member cannot view person outside their chapter" do
    sign_in_as users(:two)
    get person_url(people(:admin_person))
    assert_response :not_found
  end
end
