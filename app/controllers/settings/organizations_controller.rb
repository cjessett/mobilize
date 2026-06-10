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
    params.require(:organization).permit(:name, :slug, :time_zone)
  end
end
