# Resources owned by either an Organization (visible org-wide) or a single
# Chapter. Include and call `scoped_resource` to get the `scope` association
# plus visibility helpers.
module Scopable
  extend ActiveSupport::Concern

  included do
    belongs_to :organization
    belongs_to :access_scope, polymorphic: true

    validate :access_scope_within_organization

    # Everything a membership may see: org-scoped records plus records scoped
    # to any of the membership's accessible chapters.
    scope :visible_to, ->(membership) {
      org = membership.organization
      if membership.org_wide?
        where(organization: org)
      else
        where(organization: org).where(
          "(access_scope_type = 'Organization') OR (access_scope_type = 'Chapter' AND access_scope_id IN (?))",
          membership.accessible_chapters.select(:id)
        )
      end
    }
  end

  def org_scoped? = access_scope.is_a?(Organization)
  def chapter = access_scope.is_a?(Chapter) ? access_scope : nil

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
