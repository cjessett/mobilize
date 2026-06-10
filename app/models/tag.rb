class Tag < ApplicationRecord
  belongs_to :organization
  has_many :taggings, dependent: :destroy
  has_many :people, through: :taggings

  normalizes :name, with: ->(value) { value.strip }

  validates :name, presence: true, uniqueness: { scope: :organization_id }
end
