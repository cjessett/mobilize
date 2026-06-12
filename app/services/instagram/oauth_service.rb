require "net/http"
require "json"

# Uses Instagram Business Login (the modern Instagram-native OAuth flow).
# No Facebook Login or Pages API required — the token is an Instagram user
# token scoped directly to the connected Instagram Business Account.
class Instagram::OauthService
  AUTHORIZE_URL  = "https://www.instagram.com/oauth/authorize"
  TOKEN_URL      = "https://api.instagram.com/oauth/access_token"
  LONG_LIVED_URL = "https://graph.instagram.com/access_token"
  GRAPH_URL      = "https://graph.instagram.com/v21.0"

  SCOPES = %w[
    instagram_business_basic
    instagram_business_manage_messages
    instagram_business_manage_comments
  ].join(",").freeze

  def self.auth_url(redirect_uri:, state:)
    params = URI.encode_www_form(
      client_id:     ENV["INSTAGRAM_APP_ID"],
      redirect_uri:  redirect_uri,
      scope:         SCOPES,
      state:         state,
      response_type: "code"
    )
    "#{AUTHORIZE_URL}?#{params}"
  end

  # Exchanges the auth code for a long-lived Instagram user token and returns
  # a single-element array with the connected account's info so the controller
  # can use the same multi-account flow without changes.
  def self.exchange_and_fetch_pages(code:, redirect_uri:)
    short_lived = exchange_code(code: code, redirect_uri: redirect_uri)
    long_lived  = exchange_for_long_lived(short_lived_token: short_lived)
    user        = get_user_info(long_lived)

    [ {
      page_id:      user["id"],
      page_name:    user["username"],
      ig_username:  user["username"],
      access_token: long_lived
    } ]
  end

  private

  def self.exchange_code(code:, redirect_uri:)
    response = post(TOKEN_URL,
      client_id:     ENV["INSTAGRAM_APP_ID"],
      client_secret: ENV["INSTAGRAM_APP_SECRET"],
      grant_type:    "authorization_code",
      redirect_uri:  redirect_uri,
      code:          code
    )
    response["access_token"]
  end

  def self.exchange_for_long_lived(short_lived_token:)
    response = get(LONG_LIVED_URL,
      grant_type:    "ig_exchange_token",
      client_secret: ENV["INSTAGRAM_APP_SECRET"],
      access_token:  short_lived_token
    )
    response["access_token"]
  end

  def self.get_user_info(access_token)
    get("#{GRAPH_URL}/me", fields: "id,username", access_token: access_token)
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
