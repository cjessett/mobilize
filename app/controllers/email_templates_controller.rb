class EmailTemplatesController < ApplicationController
  before_action :set_template, only: [ :edit, :update, :destroy ]

  def index
    @templates = current_organization.email_templates.order(:name)
  end

  def new
    @template = current_organization.email_templates.new
  end

  def create
    @template = current_organization.email_templates.new(template_params)
    if @template.save
      redirect_to email_templates_path, notice: "Template created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to email_templates_path, notice: "Template updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to email_templates_path, notice: "Template deleted."
  end

  private

  def set_template
    @template = current_organization.email_templates.find(params[:id])
  end

  def template_params
    params.require(:email_template).permit(:name, :subject, :body)
  end
end
