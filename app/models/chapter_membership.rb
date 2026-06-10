class ChapterMembership < ApplicationRecord
  belongs_to :chapter
  belongs_to :person

  validates :chapter_id, uniqueness: { scope: :person_id }
  validate :chapter_in_same_organization

  private

  def chapter_in_same_organization
    return if chapter.nil? || person.nil?

    errors.add(:chapter, "must belong to the person's organization") if chapter.organization_id != person.organization_id
  end
end
