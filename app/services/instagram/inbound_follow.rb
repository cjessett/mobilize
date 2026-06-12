class Instagram::InboundFollow
  def initialize(page_id:, follower_id:)
    @page_id = page_id
    @follower_id = follower_id
  end

  def call
    organization = Organization.find_by(instagram_page_id: @page_id)
    return nil if organization.nil?

    person = organization.people.find_by(instagram_user_id: @follower_id) ||
      organization.people.create!(instagram_user_id: @follower_id)

    Workflow.fire(
      trigger: "instagram_follow_received",
      person: person,
      payload: { instagram_user_id: @follower_id }
    )

    person
  end
end
