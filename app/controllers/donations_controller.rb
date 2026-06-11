class DonationsController < ApplicationController
  def index
    @donations = current_organization.donations.includes(:person).order(donated_at: :desc).limit(200)
    @webhook_token = current_organization.webhook_token!
  end

  def new
    @donation = current_organization.donations.new(person_id: params[:person_id], donated_at: Time.current)
  end

  def create
    @donation = current_organization.donations.new(donation_params)
    if @donation.save
      redirect_to donations_path, notice: "Donation recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def donation_params
    permitted = params.require(:donation).permit(:person_id, :amount, :source, :donated_at)
    amount = permitted.delete(:amount)
    permitted.merge(amount_cents: (amount.to_f * 100).round)
  end
end
