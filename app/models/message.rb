class Message < ApplicationRecord
  DIRECTIONS = %w[outbound inbound].freeze
  STATUSES = %w[pending queued sent delivered failed received].freeze

  belongs_to :organization
  belongs_to :person
  belongs_to :chapter, optional: true
  belongs_to :blast, optional: true
  has_many :short_links, dependent: :nullify
  has_many_attached :media

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :status, inclusion: { in: STATUSES }
  validates :body, presence: true

  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound, -> { where(direction: "inbound") }

  after_create_commit :broadcast_to_conversation, :record_activity

  def self.compose!(person:, body:, blast: nil, media: [], respect_texting_hours: false)
    send_after = DeliveryWindow.next_allowed_time(person: person, organization: person.organization) if respect_texting_hours
    message = create!(
      organization_id: person.organization_id,
      person: person,
      chapter: person.primary_chapter,
      blast: blast,
      direction: "outbound",
      body: MergeTags.render(body, person),
      status: "pending",
      send_after: send_after
    )
    message.media.attach(media) if media.present?
    if blast
      shortened = LinkShortener.rewrite(message.body, organization: message.organization, blast: blast, message: message, person: person)
      message.update!(body: shortened) if shortened != message.body
    end
    message
  end

  def deliver_later
    Message::DeliverJob.perform_later(self)
  end

  private

  def broadcast_to_conversation
    broadcast_append_to [ person, :messages ], target: "conversation_messages", partial: "conversations/message", locals: { message: self }
  end

  def record_activity
    Activity.record!(
      person: person,
      kind: direction == "inbound" ? "message_received" : "message_sent",
      subject: self,
      occurred_at: created_at
    )
  end
end
