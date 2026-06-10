require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "org-wide membership sees all chapters" do
    assert_equal organizations(:riverside).chapters.count, memberships(:admin).accessible_chapters.count
  end

  test "chapter-scoped membership sees only its chapter" do
    assert_equal [ chapters(:north) ], memberships(:organizer_north).accessible_chapters.to_a
  end

  test "access scope must belong to the organization" do
    membership = memberships(:admin)
    membership.access_scope = chapters(:other_main)
    assert_not membership.valid?
  end
end
