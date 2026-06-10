require "test_helper"

class Public::FormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = organizations(:riverside)
    @form = @org.forms.create!(title: "Petition", kind: "petition", access_scope: @org)
    @form.form_fields.create!(position: 0, key: "first_name", label: "First name", required: true)
    @form.form_fields.create!(position: 1, key: "email", label: "Email")
  end

  test "renders public form" do
    get public_form_url(@org.slug, @form.slug)
    assert_response :success
    assert_match @form.title, response.body
  end

  test "submission creates person and submission" do
    assert_difference [ "Person.count", "Submission.count" ] do
      post public_submit_form_url(@org.slug, @form.slug), params: { first_name: "Sig", email: "sig@example.com" }
    end
  end

  test "missing required fields are rejected" do
    assert_no_difference "Submission.count" do
      post public_submit_form_url(@org.slug, @form.slug), params: { email: "x@example.com" }
    end
  end
end
