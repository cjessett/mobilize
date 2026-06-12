class Instagram::InboundComment
  def initialize(page_id:, commenter_id:, commenter_username:, comment_text:, comment_id:, post_id:)
    @page_id = page_id
    @commenter_id = commenter_id
    @commenter_username = commenter_username
    @comment_text = comment_text.to_s
    @comment_id = comment_id
    @post_id = post_id
  end

  def call
    organization = Organization.find_by(instagram_page_id: @page_id)
    return nil if organization.nil?

    person = find_or_create_person(organization)

    Workflow.fire(
      trigger: "instagram_comment_received",
      person: person,
      param: first_word,
      payload: {
        comment_id: @comment_id,
        comment_text: @comment_text,
        post_id: @post_id,
        instagram_user_id: @commenter_id
      }
    )

    person
  end

  private

  def find_or_create_person(organization)
    organization.people.find_by(instagram_user_id: @commenter_id) ||
      organization.people.create!(
        instagram_user_id: @commenter_id,
        first_name: @commenter_username.presence
      )
  end

  def first_word
    @comment_text.strip.split(/\s+/).first.to_s.downcase.presence
  end
end
