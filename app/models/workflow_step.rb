class WorkflowStep < ApplicationRecord
  ACTIONS = %w[send_sms send_email add_tag remove_tag wait notify_member update_custom_field webhook rsvp_person_to_event router].freeze

  belongs_to :workflow
  belongs_to :parent_step, class_name: "WorkflowStep", optional: true
  has_many :child_steps, class_name: "WorkflowStep", foreign_key: :parent_step_id, dependent: :destroy
  has_many :workflow_step_executions, dependent: :destroy

  validates :action, inclusion: { in: ACTIONS }
  validates :position, presence: true

  def execute(person)
    case action
    when "send_sms"
      Message.compose!(person: person, body: params["body"], respect_texting_hours: true).deliver_later unless person.opted_out_sms? || person.phone.blank?
    when "send_email"
      WorkflowMailer.step_email(person, params["subject"].to_s, params["body"].to_s).deliver_later unless person.unsubscribed_email? || person.email.blank?
    when "add_tag"
      tag = workflow.organization.tags.find_or_create_by!(name: params["tag_name"].to_s.strip)
      person.taggings.find_or_create_by!(tag: tag)
    when "remove_tag"
      tag = workflow.organization.tags.find_by(name: params["tag_name"].to_s.strip)
      person.taggings.where(tag: tag).destroy_all if tag
    when "notify_member"
      user = workflow.organization.users.find_by(email_address: params["email"].to_s.strip.downcase)
      return if user.nil?

      if params["channel"] == "sms"
        phone = user.person&.phone
        Sms.provider.send_message(to: phone, body: "[Mobilize] Workflow \"#{workflow.name}\" matched #{person.name}") if phone.present?
      else
        WorkflowMailer.member_notification(user, workflow, person).deliver_later
      end
    when "update_custom_field"
      key = params["key"].to_s.strip
      person.update!(custom_field_values: person.custom_field_values.merge(key => params["value"].to_s)) if key.present?
    when "webhook"
      Workflow::WebhookJob.perform_later(workflow, person, params["url"].to_s) if params["url"].present?
    when "rsvp_person_to_event"
      event = workflow.organization.events.find_by(id: params["event_id"])
      event&.rsvp_for!(person)
    end
  end

  def wait? = action == "wait"
  def router? = action == "router"

  def router_mode
    params["mode"] == "all_matches" ? "all_matches" : "first_match"
  end

  def branches = Array(params["branches"])

  def wait_duration
    [ params["duration_minutes"].to_i, 1 ].max.minutes
  end
end
