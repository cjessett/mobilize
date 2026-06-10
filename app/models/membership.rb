class Membership < ApplicationRecord
  ROLES = %w[admin organizer].freeze

  belongs_to :user
  belongs_to :organization
  belongs_to :access_scope, polymorphic: true

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }
  validate :access_scope_within_organization

  def admin? = role == "admin"

  # Chapters this membership can see. Org-wide scope sees all chapters.
  def accessible_chapters
    case access_scope
    when Organization then organization.chapters
    when Chapter then organization.chapters.where(id: access_scope.id)
    end
  end

  def org_wide? = access_scope.is_a?(Organization)

  private

  def access_scope_within_organization
    ok = case access_scope
    when Organization then access_scope.id == organization_id
    when Chapter then access_scope.organization_id == organization_id
    else false
    end
    errors.add(:access_scope, "must be the organization or one of its chapters") unless ok
  end
end
