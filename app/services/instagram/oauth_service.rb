require "net/http"
require "json"

class Instagram::OauthService
  GRAPH_URL = "https://graph.facebook.com/v21.0"
  DIALOG_URL = "https://www.facebook.com/v21.0/dialog/oauth"
  SCOPES = %w[
    instagram_manage_messages
    instagram_manage_comments
    pages_messaging
    pages_show_list
    pages_read_engagement
  ].join(",").freeze

  def self.auth_url(redirect_uri:, state:)
    params = URI.encode_www_form(
      client_id: ENV["INSTAGRAM_APP_ID"],
      redirect_uri: redirect_uri,
      scope: SCOPES,
      state: state,
      response_type: "code"
    )
    "#{DIALOG_URL}?#{params}"
  end

  # Exchanges the OAuth code for a never-expiring Page Access Token.
  # Returns an array of page hashes:
  #   [{ page_id:, page_name:, ig_user_id:, ig_username:, access_token: }, ...]
  def self.exchange_and_fetch_pages(code:, redirect_uri:)
    short_lived = exchange_code(code: code, redirect_uri: redirect_uri)
    long_lived  = exchange_for_long_lived(user_token: short_lived)
    pages_with_instagram(user_token: long_lived)
  end

  private

  def self.exchange_code(code:, redirect_uri:)
    response = post("#{GRAPH_URL}/oauth/access_token",
      client_id:     ENV["INSTAGRAM_APP_ID"],
      client_secret: ENV["INSTAGRAM_APP_SECRET"],
      redirect_uri:  redirect_uri,
      code:          code
    )
    response["access_token"]
  end

  def self.exchange_for_long_lived(user_token:)
    response = get("#{GRAPH_URL}/oauth/access_token",
      grant_type:        "fb_exchange_token",
      client_id:         ENV["INSTAGRAM_APP_ID"],
      client_secret:     ENV["INSTAGRAM_APP_SECRET"],
      fb_exchange_token: user_token
    )
    response["access_token"]
  end

  def self.pages_with_instagram(user_token:)
    response = get("#{GRAPH_URL}/me/accounts",
      fields:       "id,name,access_token,instagram_business_account",
      access_token: user_token
    )

    pages = []
    Array(response["data"]).each do |page|
      ig_id = page.dig("instagram_business_account", "id")
      next if ig_id.blank?

      page_token = page["access_token"]
      ig_username = fetch_ig_username(ig_user_id: ig_id, access_token: page_token)

      pages << {
        page_id:      ig_id,
        page_name:    page["name"],
        ig_username:  ig_username,
        access_token: page_token
      }
    end
    pages
  end

  def self.fetch_ig_username(ig_user_id:, access_token:)
    response = get("#{GRAPH_URL}/#{ig_user_id}",
      fields:       "username",
      access_token: access_token
    )
    response["username"]
  rescue StandardError
    nil
  end

  def self.get(url, params = {})
    uri = URI(url)
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    raise "Instagram OAuth error: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def self.post(url, params = {})
    uri = URI(url)
    response = Net::HTTP.post_form(uri, params)
    raise "Instagram OAuth error: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
