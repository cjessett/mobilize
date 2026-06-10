require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "registration creates org, default chapter, person, admin user" do
    assert_difference [ "Organization.count", "User.count", "Person.count" ], 1 do
      post registration_url, params: {
        organization_name: "New Union",
        first_name: "Pat",
        last_name: "Organizer",
        email_address: "pat@example.com",
        password: "s3curep4ssword",
        password_confirmation: "s3curep4ssword",
        time_zone: "America/Chicago"
      }
    end
    assert_redirected_to root_url

    org = Organization.find_by(slug: "new-union")
    assert org.default_chapter.default?
    user = User.find_by(email_address: "pat@example.com")
    membership = user.membership_for(org)
    assert membership.admin?
    assert_equal org, membership.access_scope
    assert_equal org.default_chapter, user.person.primary_chapter
  end

  test "invalid registration re-renders with errors" do
    assert_no_difference "Organization.count" do
      post registration_url, params: { organization_name: "", email_address: "x@example.com", password: "pw", password_confirmation: "pw" }
    end
    assert_response :unprocessable_entity
  end
end
