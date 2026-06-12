# Public, no-login tools for event hosts: see RSVPs, mark attendance, and
# reach attendees. Access is via the event's secret host token.
class HostToolsController < ApplicationController
  allow_unauthenticated_access
  layout "public"

  before_action :set_event

  def show
    @sessions = @event.event_sessions.includes(rsvps: :person)
  end

  def check_in
    rsvp = @event.rsvps.find(params[:rsvp_id])
    @event.check_in!(rsvp)
    redirect_to host_tools_path(token: @event.host_token)
  end

  private

  def set_event
    @event = Event.find_by!(host_token: params[:token].presence)
    @organization = @event.organization
  end
end
