class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :check_in ]

  def index
    @tab = params[:tab] == "past" ? "past" : "upcoming"
    events = Event.visible_to(current_membership)
    @events = @tab == "past" ? events.past.limit(50) : events.upcoming
  end

  def show
    @rsvps = @event.rsvps.includes(:person).order(:created_at)
  end

  def new
    @event = current_organization.events.new(access_scope: current_organization)
  end

  def create
    @event = current_organization.events.new(event_attributes)
    if @event.save
      redirect_to @event, notice: "Event created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_attributes)
      redirect_to @event, notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Event deleted."
  end

  def check_in
    rsvp = @event.rsvps.find(params[:rsvp_id])
    rsvp.update!(attended: !rsvp.attended?)
    redirect_to @event
  end

  private

  def set_event
    @event = Event.visible_to(current_membership).find(params[:id])
  end

  def event_attributes
    permitted = params.require(:event).permit(:title, :description, :event_type, :starts_at, :ends_at, :location, :virtual_url, :capacity, :access_scope_gid)
    scope = case permitted.delete(:access_scope_gid)
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
    permitted[:starts_at] = in_org_zone(permitted[:starts_at])
    permitted[:ends_at] = in_org_zone(permitted[:ends_at])
    permitted.merge(access_scope: scope)
  end

  def in_org_zone(value)
    return nil if value.blank?

    Time.use_zone(current_organization.time_zone) { Time.zone.parse(value.to_s) }
  end
end
