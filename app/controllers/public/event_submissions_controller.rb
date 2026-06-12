# "Host an Event": supporters propose their own events, which appear in the
# admin Events list under Pending approval.
class Public::EventSubmissionsController < Public::BaseController
  def new
  end

  def create
    if params[:phone].blank? && params[:email].blank?
      return redirect_to public_host_an_event_path(@organization.slug), alert: "Please provide a phone number or email."
    end

    person = PersonUpsert.new(@organization, params.permit(:first_name, :last_name, :phone, :email, :zip_code).to_h).call
    starts_at = Time.use_zone(@organization.time_zone) { Time.zone.parse(params[:starts_at].to_s) }
    return redirect_to public_host_an_event_path(@organization.slug), alert: "Please pick a date and time." if starts_at.nil?

    @organization.events.create!(
      title: params[:title].presence || "Event hosted by #{person.name}",
      description: params[:description],
      event_type: Event::EVENT_TYPES.key?(params[:event_type]) ? params[:event_type] : "in_person",
      location: params[:location],
      starts_at: starts_at,
      access_scope: @organization,
      approved: false,
      unlisted: true,
      submitted_by: person
    )
    redirect_to public_events_path(@organization.slug), notice: "Thanks! Your event was submitted and is awaiting approval."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_host_an_event_path(@organization.slug), alert: e.record.errors.full_messages.to_sentence
  end
end
