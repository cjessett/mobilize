class ShortLink < ApplicationRecord
  # No 0/O/1/l/I to keep tokens unambiguous when read aloud.
  TOKEN_ALPHABET = (("a".."z").to_a + ("A".."Z").to_a + ("2".."9").to_a - %w[l I O]).freeze

  belongs_to :organization
  belongs_to :blast, optional: true
  belongs_to :message, optional: true
  belongs_to :person, optional: true
  has_many :link_clicks, dependent: :destroy

  validates :destination_url, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  def short_url
    Rails.application.routes.url_helpers.short_link_url(token: token)
  end

  private

  def generate_token
    self.token ||= loop do
      candidate = Array.new(8) { TOKEN_ALPHABET.sample }.join
      break candidate unless self.class.exists?(token: candidate)
    end
  end
end
