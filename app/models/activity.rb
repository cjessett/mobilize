class Activity < ApplicationRecord
  belongs_to :organization
  belongs_to :person
  belongs_to :subject, polymorphic: true, optional: true

  validates :kind, presence: true

  scope :recent_first, -> { order(occurred_at: :desc) }

  def self.record!(person:, kind:, subject: nil, data: {}, occurred_at: Time.current)
    create!(
      organization_id: person.organization_id,
      person: person,
      kind: kind,
      subject: subject,
      data: data,
      occurred_at: occurred_at
    )
  end
end
