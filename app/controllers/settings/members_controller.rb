class Settings::MembersController < ApplicationController
  require_admin

  def index
    @memberships = current_organization.memberships.includes(user: :person)
  end

  def new
    @membership = current_organization.memberships.new
  end

  def create
    ActiveRecord::Base.transaction do
      person = current_organization.people.create_with(
        first_name: params[:first_name], last_name: params[:last_name]
      ).find_or_create_by!(email: params[:email_address].to_s.strip.downcase)
      user = User.find_or_initialize_by(email_address: params[:email_address])
      if user.new_record?
        user.password = SecureRandom.base58(24)
        user.person = person
        user.save!
      end
      access_scope = if params[:chapter_id].present?
        current_organization.chapters.find(params[:chapter_id])
      else
        current_organization
      end
      current_organization.memberships.create!(user: user, role: params[:role].presence || "organizer", access_scope: access_scope)
      PasswordsMailer.reset(user).deliver_later
    end
    redirect_to settings_members_path, notice: "Member invited. They'll receive an email to set their password."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_settings_member_path, alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    membership = current_organization.memberships.find(params[:id])
    if membership.user == Current.user
      redirect_to settings_members_path, alert: "You can't remove yourself."
    else
      membership.destroy
      redirect_to settings_members_path, notice: "Member removed."
    end
  end
end
