# Subscribable iCal feed of an organization's listed upcoming events.
class Public::CalendarsController < ApplicationController
  allow_unauthenticated_access

  def feed
    organization = Organization.find_by!(slug: params[:org_slug])
    events = organization.events.listed.upcoming.includes(:event_sessions)
    render plain: IcsCalendar.feed(organization, events), content_type: "text/calendar"
  end
end
