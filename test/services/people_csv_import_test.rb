require "test_helper"

class PeopleCsvImportTest < ActiveSupport::TestCase
  test "creates new people and updates existing by phone" do
    csv = <<~CSV
      first_name,last_name,phone,email,zip_code,tags
      New,Person,555-111-0001,new@example.com,60601,"member, canvasser"
      Maria,Updated,#{people(:maria).phone},,60602,
    CSV

    result = PeopleCsvImport.new(organizations(:riverside), StringIO.new(csv)).call

    assert_equal 1, result.created
    assert_equal 1, result.updated
    assert_empty result.errors

    created = organizations(:riverside).people.find_by(phone: "+15551110001")
    assert_equal "New", created.first_name
    assert_equal %w[canvasser member], created.tags.order(:name).pluck(:name)
    assert_equal chapters(:north), created.primary_chapter

    assert_equal "Updated", people(:maria).reload.last_name
  end

  test "reports row errors without aborting" do
    csv = <<~CSV
      first_name,last_name,phone,email
      OnlyName,,,
      Good,Row,555-111-0002,
    CSV

    result = PeopleCsvImport.new(organizations(:riverside), StringIO.new(csv)).call
    assert_equal 1, result.created
    assert_equal 1, result.errors.size
  end
end
