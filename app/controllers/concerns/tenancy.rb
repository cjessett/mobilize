# Sets Current.membership (and thus Current.organization) for signed-in users.
module Tenancy
  extend ActiveSupport::Concern

  included do
    before_action :set_current_membership
    helper_method :current_membership, :current_organization
  end

  class_methods do
    def require_admin(**options)
      before_action :require_admin_membership, **options
    end
  end

  private

  def set_current_membership
    return unless authenticated?

    Current.membership = Current.user.default_membership
  end

  def current_membership = Current.membership
  def current_organization = Current.organization

  def require_admin_membership
    redirect_to root_path, alert: "You don't have permission to do that." unless current_membership&.admin?
  end
end
