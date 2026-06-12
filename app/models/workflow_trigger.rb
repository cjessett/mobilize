class WorkflowTrigger < ApplicationRecord
  belongs_to :workflow

  validates :trigger, inclusion: { in: -> (_) { Workflow::TRIGGERS } }

  # `param` matches the firing event's param when present (keyword word, tag
  # name, form slug, event id…); blank matches any. `config` holds
  # trigger-specific filters (incoming_text content match, RSVP status).
  def matches?(param:, payload: {})
    return false if self.param.present? && self.param.to_s != param.to_s

    case trigger
    when "incoming_text" then text_matches?(payload[:body].to_s)
    when "rsvp_created" then status_matches?(payload[:status])
    when "instagram_comment_received" then post_matches?(payload[:post_id]) && text_matches?(payload[:comment_text].to_s)
    when "instagram_dm_received" then text_matches?(payload[:message_text].to_s)
    else true
    end
  end

  private

  def post_matches?(post_id)
    shortcode = config["post_shortcode"].presence
    return true if shortcode.blank?

    Instagram::Shortcode.to_id(shortcode) == post_id.to_s
  end

  def text_matches?(body)
    value = config["value"].to_s
    return true if value.blank?

    case config["match_type"]
    when "exact" then body.strip.casecmp?(value.strip)
    when "regex"
      begin
        Regexp.new(value, Regexp::IGNORECASE).match?(body)
      rescue RegexpError
        false
      end
    else body.downcase.include?(value.downcase)
    end
  end

  def status_matches?(status)
    config["status"].blank? || status.to_s == config["status"].to_s
  end
end
