class BlastsController < ApplicationController
  before_action :set_blast, only: [ :show, :edit, :update, :destroy, :send_now, :schedule, :cancel, :clone, :test_send ]

  def index
    @blasts = Blast.visible_to(current_membership).order(created_at: :desc)
  end

  def show
    @stats = @blast.stats
    @recipient_count = @blast.editable? ? @blast.recipients.count : @blast.messages.count
  end

  def new
    @blast = current_organization.blasts.new(access_scope: current_organization, segment_id: params[:segment_id].presence)
    if params[:template_id] && (template = current_organization.sms_templates.find_by(id: params[:template_id]))
      @blast.body = template.body
      @blast.variants = template.variants
    end
  end

  def create
    @blast = current_organization.blasts.new(blast_params)
    if @blast.save
      redirect_to @blast, notice: "Blast created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @blast, alert: "This blast can no longer be edited." unless @blast.editable?
  end

  def update
    if @blast.update(blast_params)
      redirect_to @blast, notice: "Blast updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blast.destroy
    redirect_to blasts_path, notice: "Blast deleted."
  end

  def send_now
    @blast.schedule!
    redirect_to @blast, notice: "Blast is sending."
  end

  def schedule
    at = Time.use_zone(current_organization.time_zone) { Time.zone.parse(params[:scheduled_at].to_s) }
    if at.nil? || at <= Time.current
      redirect_to @blast, alert: "Pick a time in the future."
    else
      @blast.schedule!(at: at)
      redirect_to @blast, notice: "Blast scheduled for #{at.in_time_zone(current_organization.time_zone).strftime('%b %-d, %Y %l:%M %p %Z')}."
    end
  end

  def cancel
    @blast.cancel!
    redirect_to @blast, notice: "Blast canceled."
  end

  def clone
    copy = current_organization.blasts.create!(
      name: "#{@blast.name} (copy)",
      body: @blast.body,
      segment_id: @blast.segment_id,
      access_scope: @blast.access_scope,
      status: "draft"
    )
    copy.media.attach(@blast.media.blobs) if @blast.media.attached?
    redirect_to edit_blast_path(copy), notice: "Blast cloned."
  end

  def test_send
    phone = PhoneNumber.normalize(params[:phone])
    return redirect_to(@blast, alert: "Enter a valid phone number for the test.") unless PhoneNumber.valid?(phone)

    sample = current_organization.people.where.not(phone: nil).first || current_organization.people.first
    body = sample ? MergeTags.render(@blast.body, sample) : @blast.body
    from = current_organization.chapters.find_by(default: true)&.phone_number
    Sms.provider.send_message(to: phone, body: body, from: from)
    redirect_to @blast, notice: "Test message sent to #{PhoneNumber.format(phone)}."
  rescue Sms::Error => e
    redirect_to @blast, alert: "Test send failed: #{e.message}"
  end

  private

  def set_blast
    @blast = Blast.visible_to(current_membership).find(params[:id])
  end

  def blast_params
    permitted = params.require(:blast).permit(:name, :body, :segment_id, :access_scope_gid, :texting_hours_mode, media: [], variants: {})
    permitted[:media] = Array(permitted[:media]).compact_blank
    permitted.delete(:media) if permitted[:media].empty?
    scope = case permitted.delete(:access_scope_gid)
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
    permitted.merge(access_scope: scope)
  end
end
