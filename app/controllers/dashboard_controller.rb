class DashboardController < ApplicationController
  def show
    @organization = current_organization
    @chapters = current_membership.accessible_chapters.order(:name)
    @chapter = @chapters.find_by(id: params[:chapter_id])

    people = Person.visible_to(current_membership)
    people = people.where(id: ChapterMembership.where(chapter: @chapter).select(:person_id)) if @chapter
    @people_count = people.count
    @new_people_this_month = people.where(created_at: 30.days.ago..).count
    @opted_out_count = people.where.not(opted_out_sms_at: nil).count

    messages = @organization.messages
    messages = messages.where(chapter: @chapter) if @chapter
    @outbound_count = messages.outbound.count
    @delivered_count = messages.outbound.where(status: %w[sent delivered]).count
    @inbound_count = messages.inbound.count
    @reply_rate = @outbound_count.positive? ? (@inbound_count * 100.0 / @outbound_count).round(1) : nil

    deliveries = EmailDelivery.joins(:email_blast).where(email_blasts: { organization_id: @organization.id })
    @email_sent_count = deliveries.where(status: "sent").count
    @email_opened_count = deliveries.where.not(opened_at: nil).count
    @open_rate = @email_sent_count.positive? ? (@email_opened_count * 100.0 / @email_sent_count).round(1) : nil

    events = Event.visible_to(current_membership)
    @upcoming_events = events.upcoming.limit(5)
    past_rsvps = Rsvp.where(event: events.past, status: "yes")
    @attendance_rate = past_rsvps.any? ? (past_rsvps.where(attended: true).count * 100.0 / past_rsvps.count).round(1) : nil
    @rsvp_count = Rsvp.where(event: events, status: "yes").count

    @workflow_runs_count = WorkflowRun.joins(:workflow).where(workflows: { organization_id: @organization.id }, created_at: 30.days.ago..).count

    @scheduled_blasts = Blast.visible_to(current_membership).where(status: "scheduled").order(:scheduled_at).limit(5)

    @growth = weekly_growth(people)
    @recent_activity = Activity.where(person_id: people.select(:id)).recent_first.includes(:person, :subject).limit(10)
  end

  private

  # New people per week for the last 8 weeks: [[week_start, count], ...]
  def weekly_growth(people)
    start = 7.weeks.ago.beginning_of_week
    counts = people.where(created_at: start..).group_by { |p| p.created_at.beginning_of_week.to_date }.transform_values(&:size)
    (0..7).map do |i|
      week = (start + i.weeks).to_date
      [ week, counts[week] || 0 ]
    end
  end
end
