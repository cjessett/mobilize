class Keyword < ApplicationRecord
  belongs_to :organization
  belongs_to :tag, optional: true

  normalizes :word, with: ->(value) { value.to_s.strip.downcase }

  validates :word, presence: true, uniqueness: { scope: :organization_id }

  def self.match(organization, body)
    first_word = body.to_s.strip.split(/\s+/).first.to_s.downcase
    return nil if first_word.blank?

    organization.keywords.find_by(word: first_word)
  end

  # Applies this keyword to an inbound message's sender: tags them and
  # queues the auto-reply if configured.
  def apply!(person)
    person.taggings.find_or_create_by!(tag: tag) if tag
    Message.compose!(person: person, body: reply_body).deliver_later if reply_body.present?
  end
end
