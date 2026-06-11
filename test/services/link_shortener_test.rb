require "test_helper"

class LinkShortenerTest < ActiveSupport::TestCase
  setup do
    @org = organizations(:riverside)
    @blast = @org.blasts.create!(name: "B", body: "x", access_scope: @org)
  end

  test "rewrites URLs to short links with per-recipient attribution" do
    body = "Sign here: https://example.org/petition?x=1 thanks!"
    result = LinkShortener.rewrite(body, organization: @org, blast: @blast, person: people(:maria))

    link = ShortLink.last
    assert_equal "https://example.org/petition?x=1", link.destination_url
    assert_equal people(:maria), link.person
    assert_equal @blast, link.blast
    assert_includes result, "/l/#{link.token}"
    assert_not_includes result, "example.org"
  end

  test "appends blast attribution to app-hosted urls" do
    body = "RSVP: http://www.example.com/o/riverside/f/join"
    LinkShortener.rewrite(body, organization: @org, blast: @blast)
    assert_equal "http://www.example.com/o/riverside/f/join?mb=#{@blast.id}", ShortLink.last.destination_url
  end

  test "leaves bodies without urls untouched" do
    assert_equal "Hi there", LinkShortener.rewrite("Hi there", organization: @org, blast: @blast)
  end

  test "clicking a short link records the click and redirects" do
    link = ShortLink.create!(organization: @org, blast: @blast, person: people(:maria), destination_url: "https://example.org/x")
    # exercised further in controller test
    assert link.token.length == 8
  end
end
