class Public::BaseController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :set_current_membership
  layout "public"

  before_action :set_organization

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:org_slug])
  end
end
