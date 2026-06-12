class EventSessionsController < ApplicationController
  def create
    event = Event.visible_to(current_membership).find(params[:event_id])
    attrs = params.require(:event_session).permit(:title, :starts_at, :ends_at, :location, :virtual_url)
    attrs[:starts_at] = parse_time(attrs[:starts_at], event)
    attrs[:ends_at] = parse_time(attrs[:ends_at], event)
    session = event.event_sessions.new(attrs)
    if session.save
      redirect_to event, notice: "Session added."
    else
      redirect_to event, alert: session.errors.full_messages.to_sentence
    end
  end

  def destroy
    session = EventSession.joins(:event).where(events: { organization_id: current_organization.id }).find(params[:id])
    event = session.event
    if event.event_sessions.count <= 1
      redirect_to event, alert: "Events need at least one session."
    else
      session.destroy
      redirect_to event, notice: "Session removed."
    end
  end

  private

  def parse_time(value, event)
    return nil if value.blank?

    Time.use_zone(event.display_time_zone) { Time.zone.parse(value.to_s) }
  end
end
