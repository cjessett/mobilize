class EmailTrackingController < ApplicationController
  allow_unauthenticated_access

  TRANSPARENT_GIF = Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7").freeze

  def open
    EmailDelivery.find_by_token_for(:open_tracking, params[:token])&.mark_opened!
    send_data TRANSPARENT_GIF, type: "image/gif", disposition: "inline"
  end

  def unsubscribe
    person = Person.find_by_token_for(:unsubscribe, params[:token])
    if person
      person.update!(unsubscribed_email_at: Time.current) unless person.unsubscribed_email?
      render plain: "You've been unsubscribed from emails from #{person.organization.name}."
    else
      render plain: "Invalid unsubscribe link.", status: :not_found
    end
  end
end
