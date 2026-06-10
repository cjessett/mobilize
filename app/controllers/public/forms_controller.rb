class Public::FormsController < Public::BaseController
  before_action :set_form

  def show
  end

  def submit
    values = params.permit(*@form.form_fields.map { |f| f.key.to_sym }).to_h.stringify_keys

    missing = @form.form_fields.select { |f| f.required? && values[f.key].blank? }
    if missing.any?
      redirect_to public_form_path(@organization.slug, @form.slug), alert: "Please fill in: #{missing.map(&:label).join(', ')}." and return
    end
    if values["phone"].blank? && values["email"].blank?
      redirect_to public_form_path(@organization.slug, @form.slug), alert: "Please provide a phone number or email." and return
    end

    @form.submit!(values)
    redirect_to public_form_path(@organization.slug, @form.slug), notice: @form.confirmation_message.presence || "Thanks — you're in!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_form_path(@organization.slug, @form.slug), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_form
    @form = @organization.forms.find_by!(slug: params[:slug])
  end
end
