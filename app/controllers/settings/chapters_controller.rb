class Settings::ChaptersController < ApplicationController
  require_admin
  before_action :set_chapter, only: [ :edit, :update, :destroy, :provision_number ]

  def index
    @chapters = current_organization.chapters.order(:name)
  end

  def new
    @chapter = current_organization.chapters.new
  end

  def create
    @chapter = current_organization.chapters.new(chapter_params)
    if @chapter.save
      redirect_to settings_chapters_path, notice: "Chapter created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to settings_chapters_path, notice: "Chapter updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @chapter.default?
      redirect_to settings_chapters_path, alert: "The default chapter can't be deleted."
    else
      @chapter.destroy
      redirect_to settings_chapters_path, notice: "Chapter deleted."
    end
  end

  def provision_number
    Sms::NumberProvisioner.new(@chapter).call(area_code: params[:area_code])
    redirect_to edit_settings_chapter_path(@chapter), notice: "Number #{format_phone(@chapter.phone_number)} provisioned for #{@chapter.name}."
  rescue Sms::Error => e
    redirect_to edit_settings_chapter_path(@chapter), alert: e.message
  end

  private

  def format_phone(value) = PhoneNumber.format(value)

  def set_chapter
    @chapter = current_organization.chapters.find(params[:id])
  end

  def chapter_params
    params.require(:chapter).permit(:name, :phone_number, :zip_codes_list)
  end
end
