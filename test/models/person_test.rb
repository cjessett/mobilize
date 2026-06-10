require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "requires phone or email" do
    person = organizations(:riverside).people.new(first_name: "No")
    assert_not person.valid?
    assert_includes person.errors.full_messages.to_sentence, "Phone or email"
  end

  test "normalizes phone to E.164" do
    person = organizations(:riverside).people.create!(first_name: "Sam", phone: "(555) 987-6543")
    assert_equal "+15559876543", person.phone
  end

  test "phone unique per organization" do
    dup = organizations(:riverside).people.new(phone: people(:maria).phone)
    assert_not dup.valid?

    other_org = organizations(:other_org).people.new(phone: people(:maria).phone)
    assert other_org.valid?
  end

  test "auto-assigns primary chapter from zip code" do
    person = organizations(:riverside).people.create!(first_name: "Zip", phone: "+15551239999", zip_code: "60601")
    assert_equal chapters(:north), person.primary_chapter
  end

  test "falls back to default chapter without zip match" do
    person = organizations(:riverside).people.create!(first_name: "NoZip", phone: "+15551238888")
    assert_equal chapters(:main), person.primary_chapter
  end

  test "reassigning primary chapter demotes the old one" do
    person = people(:maria)
    person.assign_primary_chapter(chapter: chapters(:main))
    assert_equal chapters(:main), person.reload.primary_chapter
    assert_equal 1, person.chapter_memberships.where(primary: true).count
  end
end
