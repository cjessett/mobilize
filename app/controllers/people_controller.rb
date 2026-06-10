class PeopleController < ApplicationController
  before_action :set_person, only: [ :show, :edit, :update, :destroy ]

  def index
    @people = Person.visible_to(current_membership).search(params[:q])
    @people = @people.where(id: ChapterMembership.where(chapter_id: params[:chapter_id]).select(:person_id)) if params[:chapter_id].present?
    @people = @people.order(:first_name, :last_name).limit(200).includes(:tags, :chapters)
  end

  def show
    @activities = @person.activities.recent_first.includes(:subject).limit(50)
    @note = @person.notes.new
  end

  def new
    @person = current_organization.people.new
  end

  def create
    @person = current_organization.people.new(person_params)
    if @person.save
      redirect_to @person, notice: "Person created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @person.update(person_params)
      @person.assign_primary_chapter(chapter: current_organization.chapters.find(params[:person][:primary_chapter_id])) if params[:person][:primary_chapter_id].present?
      redirect_to @person, notice: "Person updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to people_path, notice: "Person deleted."
  end

  def import
    return unless request.post?

    if params[:file].blank?
      redirect_to import_people_path, alert: "Choose a CSV file." and return
    end

    result = PeopleCsvImport.new(current_organization, params[:file]).call
    message = "Imported #{result.created} new, updated #{result.updated}."
    if result.errors.any?
      flash[:alert] = "#{message} #{result.errors.size} rows failed: #{result.errors.first(3).join('; ')}"
    else
      flash[:notice] = message
    end
    redirect_to people_path
  end

  private

  def set_person
    @person = Person.visible_to(current_membership).find(params[:id])
  end

  def person_params
    permitted = params.require(:person).permit(
      :first_name, :last_name, :phone, :email, :address, :city, :state, :zip_code,
      :preferred_language, :do_not_call, :tag_list, custom_field_values: {}
    )
    permitted[:custom_field_values] = (@person&.custom_field_values || {}).merge(permitted[:custom_field_values] || {}) if permitted.key?(:custom_field_values)
    permitted
  end
end
