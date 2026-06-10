require "test_helper"

class FormTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @form = @org.forms.create!(title: "Join Us", kind: "petition", goal: 100, access_scope: @org,
      apply_tag: @org.tags.create!(name: "signer"))
    @form.form_fields.create!(position: 0, key: "first_name", label: "First name", required: true)
    @form.form_fields.create!(position: 1, key: "phone", label: "Phone")
    @form.form_fields.create!(position: 2, key: "zip_code", label: "Zip")
  end

  test "submit! upserts person, tags, records activity, fires workflow" do
    workflow = @org.workflows.create!(name: "W", trigger: "form_submitted", trigger_param: "join-us", access_scope: @org)
    workflow.workflow_steps.create!(position: 0, action: "add_tag", params: { "tag_name" => "followed-up" })

    assert_difference [ "Person.count", "Submission.count", "WorkflowRun.count" ] do
      @form.submit!({ "first_name" => "Sal", "phone" => "555-666-7777", "zip_code" => "60601" })
    end

    person = @org.people.find_by(phone: "+15556667777")
    assert_equal chapters(:north), person.primary_chapter
    assert_includes person.tags.pluck(:name), "signer"
  end

  test "submit! matches existing person by phone" do
    assert_no_difference "Person.count" do
      @form.submit!({ "first_name" => "Maria", "phone" => people(:maria).phone })
    end
    assert_includes people(:maria).tags.pluck(:name), "signer"
  end

  test "custom field values flow through to the person" do
    @org.custom_fields.create!(label: "Workplace", key: "workplace")
    @form.form_fields.create!(position: 3, key: "workplace", label: "Workplace")

    @form.submit!({ "first_name" => "Cee", "phone" => "555-888-9999", "workplace" => "Acme" })
    assert_equal "Acme", @org.people.find_by(phone: "+15558889999").custom_field_values["workplace"]
  end

  test "slug generated from title and unique per org" do
    assert_equal "join-us", @form.slug
    dup = @org.forms.new(title: "Join Us", access_scope: @org)
    assert_not dup.valid?
  end
end
