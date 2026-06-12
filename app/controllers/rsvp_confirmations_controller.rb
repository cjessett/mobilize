class RsvpConfirmationsController < ApplicationController
  allow_unauthenticated_access
  layout "public"

  def show
    @rsvp = Rsvp.find_by_token_for(:confirmation, params[:token])
    if @rsvp
      @rsvp.confirm!
      @organization = @rsvp.event.organization
      render plain: "You're confirmed for #{@rsvp.event.title}. See you there!"
    else
      render plain: "This confirmation link is invalid or has expired.", status: :not_found
    end
  end
end
