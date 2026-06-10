require "test_helper"

class PhoneNumberTest < ActiveSupport::TestCase
  test "formats US E.164 numbers for display" do
    assert_equal "(805) 878-4343", PhoneNumber.format("+18058784343")
  end

  test "leaves non-US and unrecognized values alone" do
    assert_equal "+447911123456", PhoneNumber.format("+447911123456")
    assert_nil PhoneNumber.format(nil)
    assert_equal "", PhoneNumber.format("")
  end

  test "person name falls back to formatted phone" do
    person = organizations(:riverside).people.create!(phone: "805-878-4343")
    assert_equal "(805) 878-4343", person.name
  end
end
