class Settings::CustomFieldsController < ApplicationController
  require_admin

  def index
    @custom_fields = current_organization.custom_fields.order(:label)
    @custom_field = current_organization.custom_fields.new
  end

  def create
    @custom_field = current_organization.custom_fields.new(custom_field_params)
    if @custom_field.save
      redirect_to settings_custom_fields_path, notice: "Custom field added."
    else
      redirect_to settings_custom_fields_path, alert: @custom_field.errors.full_messages.to_sentence
    end
  end

  def destroy
    current_organization.custom_fields.find(params[:id]).destroy
    redirect_to settings_custom_fields_path, notice: "Custom field removed."
  end

  private

  def custom_field_params
    params.require(:custom_field).permit(:label, :key, :field_type)
  end
end
