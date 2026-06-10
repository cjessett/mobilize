class Webhooks::TwilioController < ActionController::Base
  skip_forgery_protection
  before_action :validate_signature

  def inbound_sms
    InboundSms.new(
      to: params[:To],
      from: params[:From],
      body: params[:Body],
      provider_sid: params[:MessageSid]
    ).call
    render xml: "<Response></Response>"
  end

  def sms_status
    message = Message.find_by(provider_sid: params[:MessageSid] || params[:SmsSid])
    if message && %w[queued sent delivered undelivered failed].include?(params[:MessageStatus])
      status = case params[:MessageStatus]
      when "delivered" then "delivered"
      when "undelivered", "failed" then "failed"
      else message.status == "delivered" ? "delivered" : params[:MessageStatus]
      end
      message.update!(status: status, error_message: params[:ErrorCode].presence)
    end
    head :ok
  end

  private

  def validate_signature
    return if Sms.provider.valid_webhook?(request.original_url, request.POST, request.headers["X-Twilio-Signature"].to_s)

    head :forbidden
  end
end
