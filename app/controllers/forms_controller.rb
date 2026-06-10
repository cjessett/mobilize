class FormsController < ApplicationController
  before_action :set_form, only: [ :show, :edit, :update, :destroy ]

  def index
    @forms = Form.visible_to(current_membership).order(:title)
  end

  def show
    @submissions = @form.submissions.order(created_at: :desc).limit(100).includes(:person)
  end

  def new
    @form = current_organization.forms.new(access_scope: current_organization, kind: params[:kind].presence_in(Form::KINDS) || "signup")
  end

  def create
    @form = current_organization.forms.new(form_attributes)
    if @form.save
      save_fields
      redirect_to @form, notice: "Form created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @form.update(form_attributes)
      save_fields
      redirect_to @form, notice: "Form updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @form.destroy
    redirect_to forms_path, notice: "Form deleted."
  end

  private

  def set_form
    @form = Form.visible_to(current_membership).find(params[:id])
  end

  def form_attributes
    permitted = params.require(:form).permit(:kind, :title, :slug, :description, :goal, :confirmation_message, :apply_tag_name, :access_scope_gid)
    tag_name = permitted.delete(:apply_tag_name)
    permitted[:apply_tag] = tag_name.present? ? current_organization.tags.find_or_create_by!(name: tag_name.strip) : nil
    scope = case permitted.delete(:access_scope_gid)
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
    permitted.merge(access_scope: scope)
  end

  def save_fields
    fields = params[:form][:fields] || {}
    available = Form::BUILTIN_FIELDS.merge(current_organization.custom_fields.pluck(:key, :label).to_h)
    @form.form_fields.destroy_all
    position = 0
    available.each do |key, default_label|
      config = fields[key]
      next unless config.is_a?(ActionController::Parameters) && config[:include] == "1"

      @form.form_fields.create!(
        position: position,
        key: key,
        label: config[:label].presence || default_label,
        required: config[:required] == "1"
      )
      position += 1
    end
  end
end
