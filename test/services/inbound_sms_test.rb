require "test_helper"

class InboundSmsTest < ActiveSupport::TestCase
  test "records inbound message for existing person on the receiving chapter" do
    message = InboundSms.new(to: chapters(:north).phone_number, from: people(:maria).phone, body: "hello there").call

    assert_equal "inbound", message.direction
    assert_equal people(:maria), message.person
    assert_equal chapters(:north), message.chapter
  end

  test "creates a person for unknown numbers, assigned to the receiving chapter" do
    assert_difference "Person.count" do
      InboundSms.new(to: chapters(:north).phone_number, from: "+15559998888", body: "hi").call
    end
    person = organizations(:riverside).people.find_by(phone: "+15559998888")
    assert_equal chapters(:north), person.primary_chapter
  end

  test "STOP opts out, START opts back in" do
    InboundSms.new(to: chapters(:north).phone_number, from: people(:maria).phone, body: "STOP").call
    assert people(:maria).reload.opted_out_sms?

    InboundSms.new(to: chapters(:north).phone_number, from: people(:maria).phone, body: "START").call
    assert_not people(:maria).reload.opted_out_sms?
  end

  test "keyword tags the sender and queues auto-reply" do
    org = organizations(:riverside)
    org.keywords.create!(word: "join", tag: org.tags.create!(name: "joined"), reply_body: "Welcome {{first_name}}!")

    assert_enqueued_with(job: Message::DeliverJob) do
      InboundSms.new(to: chapters(:north).phone_number, from: people(:maria).phone, body: "JOIN please").call
    end
    assert_includes people(:maria).reload.tags.pluck(:name), "joined"
    reply = people(:maria).messages.outbound.last
    assert_equal "Welcome Maria!", reply.body
  end

  test "returns nil for unknown receiving number" do
    assert_nil InboundSms.new(to: "+19990000000", from: "+15551112222", body: "hi").call
  end
end
