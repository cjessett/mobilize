class Settings::InstagramController < ApplicationController
  require_admin

  def connect
    session[:instagram_oauth_state] = SecureRandom.hex(16)
    redirect_to Instagram::OauthService.auth_url(
      redirect_uri: callback_url,
      state: session[:instagram_oauth_state]
    ), allow_other_host: true
  end

  def callback
    unless params[:state] == session.delete(:instagram_oauth_state)
      redirect_to settings_organization_path, alert: "Invalid OAuth state. Please try again."
      return
    end

    if params[:error].present?
      redirect_to settings_organization_path, alert: "Instagram connection cancelled."
      return
    end

    pages = Instagram::OauthService.exchange_and_fetch_pages(
      code: params[:code],
      redirect_uri: callback_url
    )

    if pages.empty?
      redirect_to settings_organization_path,
        alert: "No Instagram Business accounts found connected to your Facebook Pages. Make sure your Instagram account is set to Business or Creator and linked to a Facebook Page."
      return
    end

    if pages.one?
      save_page(pages.first)
      redirect_to settings_organization_path,
        notice: "Instagram connected as @#{pages.first[:ig_username]}."
    else
      session[:instagram_pages] = pages.map(&:stringify_keys)
      redirect_to select_page_settings_instagram_index_path
    end
  rescue => e
    Rails.logger.error("[Settings::Instagram] OAuth error: #{e.message}")
    redirect_to settings_organization_path, alert: "Could not connect Instagram. Please check your app credentials and try again."
  end

  def select_page
    @pages = session[:instagram_pages]
    redirect_to settings_organization_path if @pages.blank?
  end

  def connect_page
    pages = session[:instagram_pages] || []
    page = pages.find { |p| p["page_id"] == params[:page_id] }

    unless page
      redirect_to settings_organization_path, alert: "Page not found."
      return
    end

    session.delete(:instagram_pages)
    save_page(page.symbolize_keys)
    redirect_to settings_organization_path,
      notice: "Instagram connected as @#{page["ig_username"]}."
  end

  def destroy
    current_organization.update!(
      instagram_page_id: nil,
      instagram_access_token: nil,
      instagram_username: nil
    )
    redirect_to settings_organization_path, notice: "Instagram disconnected."
  end

  private

  def callback_url
    settings_instagram_callback_url(host: request.host_with_port, protocol: request.protocol)
  end

  def save_page(page)
    current_organization.update!(
      instagram_page_id:     page[:page_id],
      instagram_access_token: page[:access_token],
      instagram_username:    page[:ig_username]
    )
  end
end
