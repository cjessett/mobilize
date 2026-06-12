class Webhooks::InstagramController < ActionController::Base
  skip_forgery_protection

  def verify
    if params["hub.mode"] == "subscribe" &&
       params["hub.verify_token"] == ENV["INSTAGRAM_WEBHOOK_VERIFY_TOKEN"]
      render plain: params["hub.challenge"]
    else
      head :forbidden
    end
  end

  def create
    raw_body = request.body.read
    unless valid_signature?(raw_body)
      head :forbidden
      return
    end

    payload = JSON.parse(raw_body)
    Array(payload["entry"]).each do |entry|
      page_id = entry["id"].to_s
      Array(entry["changes"]).each { |change| handle_change(page_id, change) }
      Array(entry["messaging"]).each { |event| handle_messaging(page_id, event) }
    end

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def valid_signature?(raw_body)
    return true if ENV["INSTAGRAM_APP_SECRET"].blank?

    provider = Instagram::Provider.new(nil, nil)
    provider.valid_webhook_signature?(raw_body, request.headers["X-Hub-Signature-256"].to_s)
  end

  def handle_change(page_id, change)
    value = change["value"] || {}
    case change["field"]
    when "comments"
      from = value["from"] || {}
      Instagram::InboundComment.new(
        page_id: page_id,
        commenter_id: from["id"].to_s,
        commenter_username: from["username"].to_s,
        comment_text: value["text"].to_s,
        comment_id: value["id"].to_s,
        post_id: value.dig("media", "id").to_s
      ).call
    when "follows"
      follower_id = value.dig("from", "id").to_s
      Instagram::InboundFollow.new(page_id: page_id, follower_id: follower_id).call if follower_id.present?
    end
  end

  def handle_messaging(page_id, event)
    sender_id = event.dig("sender", "id").to_s
    message = event["message"]
    return if message.nil? || message["is_echo"]

    quick_reply_payload = message.dig("quick_reply", "payload")
    text = message["text"].to_s

    Instagram::InboundDm.new(
      page_id: page_id,
      sender_id: sender_id,
      message_text: text,
      quick_reply_payload: quick_reply_payload
    ).call
  end
end
