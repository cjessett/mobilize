class Public::EventsController < Public::BaseController
  def index
    @events = @organization.events.upcoming
  end

  def show
    @event = @organization.events.find(params[:id])
  end

  def rsvp
    @event = @organization.events.find(params[:id])
    if params[:phone].blank? && params[:email].blank?
      redirect_to public_event_path(@organization.slug, @event), alert: "Please provide a phone number or email." and return
    end

    person = PersonUpsert.new(@organization, params.permit(:first_name, :last_name, :phone, :email, :zip_code).to_h).call
    rsvp = @event.rsvp_for!(person)
    notice = rsvp.status == "waitlist" ? "This event is full — you've been added to the waitlist." : "You're confirmed! See you there."
    redirect_to public_event_path(@organization.slug, @event), notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_event_path(@organization.slug, @event), alert: e.record.errors.full_messages.to_sentence
  end
end
