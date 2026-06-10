class Message < ApplicationRecord
  DIRECTIONS = %w[outbound inbound].freeze
  STATUSES = %w[pending queued sent delivered failed received].freeze

  belongs_to :organization
  belongs_to :person
  belongs_to :chapter, optional: true
  belongs_to :blast, optional: true

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :status, inclusion: { in: STATUSES }
  validates :body, presence: true

  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound, -> { where(direction: "inbound") }

  after_create_commit :broadcast_to_conversation, :record_activity

  def self.compose!(person:, body:, blast: nil)
    create!(
      organization_id: person.organization_id,
      person: person,
      chapter: person.primary_chapter,
      blast: blast,
      direction: "outbound",
      body: MergeTags.render(body, person),
      status: "pending"
    )
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
