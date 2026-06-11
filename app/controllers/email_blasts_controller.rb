class EmailBlastsController < ApplicationController
  before_action :set_email_blast, only: [ :show, :edit, :update, :destroy, :send_now, :schedule, :cancel ]

  def index
    @email_blasts = EmailBlast.visible_to(current_membership).order(created_at: :desc)
  end

  def show
    @stats = @email_blast.stats
    @recipient_count = @email_blast.editable? ? @email_blast.recipients.count : @email_blast.email_deliveries.count
  end

  def new
    @email_blast = current_organization.email_blasts.new(access_scope: current_organization)
    if params[:email_template_id] && (template = current_organization.email_templates.find_by(id: params[:email_template_id]))
      @email_blast.subject = template.subject
      @email_blast.body = template.body.body
    end
  end

  def create
    @email_blast = current_organization.email_blasts.new(email_blast_params)
    if @email_blast.save
      redirect_to @email_blast, notice: "Email blast created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @email_blast, alert: "This blast can no longer be edited." unless @email_blast.editable?
  end

  def update
    if @email_blast.update(email_blast_params)
      redirect_to @email_blast, notice: "Email blast updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @email_blast.destroy
    redirect_to email_blasts_path, notice: "Email blast deleted."
  end

  def send_now
    @email_blast.schedule!
    redirect_to @email_blast, notice: "Email blast is sending."
  end

  def schedule
    at = Time.use_zone(current_organization.time_zone) { Time.zone.parse(params[:scheduled_at].to_s) }
    if at.nil? || at <= Time.current
      redirect_to @email_blast, alert: "Pick a time in the future."
    else
      @email_blast.schedule!(at: at)
      redirect_to @email_blast, notice: "Email blast scheduled."
    end
  end

  def cancel
    @email_blast.cancel!
    redirect_to @email_blast, notice: "Email blast canceled."
  end

  private

  def set_email_blast
    @email_blast = EmailBlast.visible_to(current_membership).find(params[:id])
  end

  def email_blast_params
    permitted = params.require(:email_blast).permit(:name, :subject, :body, :segment_id, :access_scope_gid)
    scope = case permitted.delete(:access_scope_gid)
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
    permitted.merge(access_scope: scope)
  end
end
