class Settings::OrganizationsController < ApplicationController
  require_admin

  def show
    @organization = current_organization
  end

  def update
    @organization = current_organization
    if @organization.update(organization_params)
      redirect_to settings_organization_path, notice: "Organization updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def organization_params
    permitted = params.require(:organization).permit(:name, :slug, :time_zone, :texting_hours_start, :texting_hours_end, texting_days: [])
    permitted[:texting_days] = Array(permitted[:texting_days]).compact_blank.map(&:to_i) if permitted.key?(:texting_days)
    permitted
  end
end
