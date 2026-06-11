require "test_helper"

class BlastSendJobTest < ActiveJob::TestCase
  setup do
    travel_to Time.utc(2026, 6, 10, 17, 0) # noon Chicago, inside texting hours
    @org = organizations(:riverside)
    @blast = @org.blasts.create!(name: "Test", body: "Hi {{first_name}}!", access_scope: @org, status: "scheduled")
  end

  test "sends personalized messages from each person's chapter number" do
    perform_enqueued_jobs { Blast::SendJob.perform_now(@blast) }

    assert_equal "sent", @blast.reload.status
    maria_message = @blast.messages.find_by(person: people(:maria))
    assert_equal "Hi Maria!", maria_message.body
    assert_equal chapters(:north), maria_message.chapter
    assert_equal "sent", maria_message.status

    delivery = fake_sms.deliveries.find { |d| d[:to] == people(:maria).phone }
    assert_equal chapters(:north).phone_number, delivery[:from]
  end

  test "skips opted-out people and dedupes phones" do
    people(:maria).update!(opted_out_sms_at: Time.current)
    perform_enqueued_jobs { Blast::SendJob.perform_now(@blast) }

    assert_nil @blast.messages.find_by(person: people(:maria))
    assert_equal 1, @blast.messages.count
  end

  test "does nothing unless blast is scheduled" do
    @blast.update!(status: "canceled")
    Blast::SendJob.perform_now(@blast)
    assert_empty @blast.messages
  end

  test "blast media is sent as MMS urls" do
    @blast.media.attach(io: file_fixture("pixel.png").open, filename: "pixel.png", content_type: "image/png")
    perform_enqueued_jobs { Blast::SendJob.perform_now(@blast) }

    maria_message = @blast.messages.find_by(person: people(:maria))
    assert maria_message.media.attached?
    delivery = fake_sms.deliveries.find { |d| d[:to] == people(:maria).phone }
    assert_equal 1, delivery[:media_urls].size
    assert_match %r{http://www\.example\.com/rails/active_storage}, delivery[:media_urls].first
  end

  test "recipients get their preferred language variant" do
    people(:maria).update!(preferred_language: "Spanish")
    @blast.update!(variants: { "es" => { "body" => "¡Hola {{first_name}}!" } })
    perform_enqueued_jobs { Blast::SendJob.perform_now(@blast) }

    assert_equal "¡Hola Maria!", @blast.messages.find_by(person: people(:maria)).body
    assert_equal "Hi Alex!", @blast.messages.find_by(person: people(:admin_person)).body
  end

  test "segment audience limits recipients" do
    segment = @org.segments.create!(name: "North", access_scope: @org, definition: { "conditions" => [ { "type" => "chapter", "chapter_id" => chapters(:north).id } ] })
    @blast.update!(segment: segment)
    perform_enqueued_jobs { Blast::SendJob.perform_now(@blast) }

    assert_equal [ people(:maria) ], @blast.messages.map(&:person)
  end
end
