class Public::EventsController < Public::BaseController
  def index
    @events = @organization.events.listed.upcoming
  end

  def show
    @event = @organization.events.approved.find(params[:id])
    @sessions = @event.event_sessions.upcoming.presence || @event.event_sessions
  end

  def rsvp
    @event = @organization.events.approved.find(params[:id])
    if params[:phone].blank? && params[:email].blank?
      redirect_to public_event_path(@organization.slug, @event), alert: "Please provide a phone number or email." and return
    end

    person = PersonUpsert.new(@organization, params.permit(:first_name, :last_name, :phone, :email, :zip_code).to_h).call
    session = @event.event_sessions.find_by(id: params[:session_id])
    status = Rsvp::STATUSES.include?(params[:status]) ? params[:status] : "yes"
    rsvp = @event.rsvp_for!(person, session: session, status: status)
    notice = case rsvp.status
    when "waitlist" then "This session is full — you've been added to the waitlist."
    when "yes" then "You're confirmed! See you there."
    when "maybe" then "Thanks — we've marked you as a maybe."
    else "Thanks for letting us know."
    end
    redirect_to public_event_path(@organization.slug, @event), notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_event_path(@organization.slug, @event), alert: e.record.errors.full_messages.to_sentence
  end

  def calendar
    @event = @organization.events.approved.find(params[:id])
    render plain: IcsCalendar.for_event(@event), content_type: "text/calendar"
  end
end
