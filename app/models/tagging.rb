class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :person

  validates :tag_id, uniqueness: { scope: :person_id }
end
