class ChapterZipCode < ApplicationRecord
  belongs_to :chapter

  validates :zip_code, presence: true, format: { with: /\A\d{5}\z/ }, uniqueness: { scope: :chapter_id }
end
