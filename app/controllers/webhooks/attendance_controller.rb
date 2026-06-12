# Marks attendance from an external source (e.g. a Zoom webhook relay):
# POST /webhooks/attendance/:token with JSON
# { event_id, session_id (optional), phone or email, first_name, last_name }
class Webhooks::AttendanceController < ActionController::Base
  skip_forgery_protection

  def create
    organization = Organization.find_by(webhook_token: params[:token].presence)
    return head :forbidden unless organization

    event = organization.events.find_by(id: params[:event_id])
    return render json: { error: "unknown event" }, status: :unprocessable_entity unless event

    attributes = params.permit(:phone, :email, :first_name, :last_name).to_h
    return head :unprocessable_entity if attributes[:phone].blank? && attributes[:email].blank?

    person = PersonUpsert.new(organization, attributes).call
    session = event.event_sessions.find_by(id: params[:session_id]) || event.next_session || event.primary_session
    rsvp = event.rsvp_for!(person, session: session)
    event.check_in!(rsvp) unless rsvp.attended?
    render json: { rsvp_id: rsvp.id, attended: true }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
