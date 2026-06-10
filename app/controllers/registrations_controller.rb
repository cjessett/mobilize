class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    user = nil
    ActiveRecord::Base.transaction do
      organization = Organization.create!(name: params[:organization_name], time_zone: params[:time_zone].presence || "UTC")
      chapter = organization.chapters.create!(name: "Main", default: true)
      person = organization.people.create!(
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email_address],
        phone: params[:phone].presence
      )
      person.assign_primary_chapter(chapter: chapter)
      user = User.create!(
        email_address: params[:email_address],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        person: person
      )
      user.memberships.create!(organization: organization, role: "admin", access_scope: organization)
    end
    start_new_session_for(user)
    redirect_to root_path, notice: "Welcome to Mobilize!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end
end
