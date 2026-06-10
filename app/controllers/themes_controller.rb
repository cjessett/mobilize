class ThemesController < ApplicationController
  allow_unauthenticated_access

  def update
    theme = params[:theme] == "light" ? "light" : "dark"
    cookies[:theme] = { value: theme, expires: 1.year }
    redirect_back fallback_location: root_path
  end
end
