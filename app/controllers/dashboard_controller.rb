class DashboardController < ApplicationController
  def show
    @organization = current_organization
    @people_count = @organization.people.count
    @chapters = @organization.chapters.order(:name)
  end
end
