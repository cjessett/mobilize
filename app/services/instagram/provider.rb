require "net/http"
require "json"
require "openssl"

class Instagram::Provider
  GRAPH_URL = "https://graph.instagram.com/v21.0"

  def initialize(page_id, access_token)
    @page_id = page_id
    @access_token = access_token
  end

  def send_dm_to_comment(comment_id:, body:, button_text: nil, button_payload: nil, button_url: nil)
    post_message(
      recipient: { comment_id: comment_id },
      message: build_message(body, button_text: button_text, button_payload: button_payload, button_url: button_url)
    )
  end

  def send_dm_to_user(instagram_user_id:, body:, button_text: nil, button_payload: nil, button_url: nil)
    post_message(
      recipient: { id: instagram_user_id },
      message: build_message(body, button_text: button_text, button_payload: button_payload, button_url: button_url)
    )
  end

  def valid_webhook_signature?(raw_body, signature_header)
    return false if ENV["INSTAGRAM_APP_SECRET"].blank?
    expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", ENV["INSTAGRAM_APP_SECRET"], raw_body)}"
    ActiveSupport::SecurityUtils.secure_compare(expected, signature_header.to_s)
  end

  private

  def build_message(body, button_text:, button_payload:, button_url:)
    if button_url.present? && button_text.present?
      {
        attachment: {
          type: "template",
          payload: {
            template_type: "button",
            text: body,
            buttons: [ { type: "web_url", url: button_url, title: button_text } ]
          }
        }
      }
    elsif button_text.present? && button_payload.present?
      {
        text: body,
        quick_replies: [ { content_type: "text", title: button_text, payload: button_payload } ]
      }
    else
      { text: body }
    end
  end

  def post_message(payload)
    uri = URI("#{GRAPH_URL}/#{@page_id}/messages")
    uri.query = URI.encode_www_form(access_token: @access_token)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json
    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[Instagram::Provider] send_message failed #{response.code}: #{response.body}")
    end
    response
  end
end
