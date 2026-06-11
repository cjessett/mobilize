class Webhooks::DonationsController < ActionController::Base
  skip_forgery_protection

  # Accepts donation notifications from external payment processors:
  # POST /webhooks/donations/:token with JSON
  # { phone or email, first_name, last_name, amount_cents, source, donated_at }
  def create
    organization = Organization.find_by(webhook_token: params[:token].presence)
    return head :forbidden unless organization

    attributes = params.permit(:phone, :email, :first_name, :last_name).to_h
    return head :unprocessable_entity if attributes[:phone].blank? && attributes[:email].blank?

    person = PersonUpsert.new(organization, attributes).call
    donation = organization.donations.create!(
      person: person,
      amount_cents: params.require(:amount_cents).to_i,
      source: params[:source],
      donated_at: params[:donated_at].presence || Time.current
    )
    render json: { id: donation.id }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
