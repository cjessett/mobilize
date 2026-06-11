class EmailTemplate < ApplicationRecord
  belongs_to :organization
  has_rich_text :body

  validates :name, :subject, presence: true
  validate { errors.add(:body, "can't be blank") if body.blank? }
end
