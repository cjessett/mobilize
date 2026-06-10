class WorkflowStep < ApplicationRecord
  ACTIONS = %w[send_sms send_email add_tag remove_tag wait notify_member].freeze

  belongs_to :workflow

  validates :action, inclusion: { in: ACTIONS }
  validates :position, presence: true

  def execute(person)
    case action
    when "send_sms"
      Message.compose!(person: person, body: params["body"]).deliver_later unless person.opted_out_sms? || person.phone.blank?
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
      WorkflowMailer.member_notification(user, workflow, person).deliver_later if user
    end
  end

  def wait? = action == "wait"

  def wait_duration
    [ params["duration_minutes"].to_i, 1 ].max.minutes
  end
end
