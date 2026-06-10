require "test_helper"

class SegmentTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
  end

  def build_segment(match: "all", conditions: [])
    @org.segments.create!(name: "Test", access_scope: @org, definition: { "match" => match, "conditions" => conditions })
  end

  test "field equals condition" do
    segment = build_segment(conditions: [ { "type" => "field", "field" => "zip_code", "op" => "eq", "value" => "60601" } ])
    assert_includes segment.people, people(:maria)
    assert_not_includes segment.people, people(:admin_person)
  end

  test "tag has and not_has conditions" do
    tag = @org.tags.create!(name: "member")
    people(:maria).taggings.create!(tag: tag)

    has = build_segment(conditions: [ { "type" => "tag", "op" => "has", "tag_id" => tag.id } ])
    assert_equal [ people(:maria) ], has.people.to_a

    not_has = build_segment(conditions: [ { "type" => "tag", "op" => "not_has", "tag_id" => tag.id } ])
    assert_not_includes not_has.people, people(:maria)
    assert_includes not_has.people, people(:admin_person)
  end

  test "chapter condition" do
    segment = build_segment(conditions: [ { "type" => "chapter", "chapter_id" => chapters(:north).id } ])
    assert_equal [ people(:maria) ], segment.people.to_a
  end

  test "custom field condition" do
    people(:maria).update!(custom_field_values: { "union_member" => "yes" })
    segment = build_segment(conditions: [ { "type" => "custom_field", "key" => "union_member", "op" => "eq", "value" => "yes" } ])
    assert_equal [ people(:maria) ], segment.people.to_a
  end

  test "match any unions conditions" do
    segment = build_segment(match: "any", conditions: [
      { "type" => "field", "field" => "zip_code", "op" => "eq", "value" => "60601" },
      { "type" => "field", "field" => "email", "op" => "eq", "value" => "one@example.com" }
    ])
    assert_includes segment.people, people(:maria)
    assert_includes segment.people, people(:admin_person)
  end

  test "match all intersects conditions" do
    segment = build_segment(conditions: [
      { "type" => "field", "field" => "zip_code", "op" => "eq", "value" => "60601" },
      { "type" => "field", "field" => "email", "op" => "present" }
    ])
    assert_empty segment.people.to_a
  end

  test "no conditions matches everyone in the org" do
    segment = build_segment
    assert_equal @org.people.count, segment.people.count
  end
end
