class WorkflowsController < ApplicationController
  before_action :set_workflow, only: [ :show, :edit, :update, :destroy, :toggle ]

  def index
    @workflows = Workflow.visible_to(current_membership).order(:name).includes(:workflow_steps, :workflow_triggers)
  end

  def show
    @runs = @workflow.workflow_runs.order(created_at: :desc).limit(50).includes(:person)
    @run_stats = @workflow.workflow_runs.group(:status).count
    @step_counts = @workflow.workflow_step_executions.group(:workflow_step_id).distinct.count(:person_id)
  end

  def new
    @workflow = current_organization.workflows.new(access_scope: current_organization)
  end

  def create
    @workflow = current_organization.workflows.new(workflow_attributes)
    if @workflow.save
      save_triggers
      save_steps
      redirect_to @workflow, notice: "Workflow created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workflow.update(workflow_attributes)
      save_triggers
      save_steps
      redirect_to @workflow, notice: "Workflow updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workflow.destroy
    redirect_to workflows_path, notice: "Workflow deleted."
  end

  def toggle
    @workflow.update!(enabled: !@workflow.enabled?)
    redirect_to @workflow, notice: @workflow.enabled? ? "Workflow enabled." : "Workflow disabled."
  end

  private

  def set_workflow
    @workflow = Workflow.visible_to(current_membership).find(params[:id])
  end

  def workflow_attributes
    permitted = params.require(:workflow).permit(:name, :access_scope_gid, :goal_trigger, :goal_param)
    scope = case permitted.delete(:access_scope_gid)
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
    permitted.merge(access_scope: scope)
  end

  def save_triggers
    triggers = Array(params[:workflow][:triggers]).map { |t| t.permit(:trigger, :param, :match_type, :value, :status, :post_url).to_h.compact_blank }
    triggers = triggers.select { |t| Workflow::TRIGGERS.include?(t["trigger"]) }
    @workflow.workflow_triggers.destroy_all
    triggers.each do |t|
      config = t.slice("match_type", "value", "status")
      if (shortcode = Instagram::Shortcode.from_url(t["post_url"]))
        config["post_shortcode"] = shortcode
      end
      @workflow.workflow_triggers.create!(trigger: t["trigger"], param: t["param"], config: config)
    end
  end

  STEP_FIELDS = [ :action, :body, :subject, :tag_name, :duration_minutes, :email, :channel, :key, :value, :url, :event_id, :mode, :button_text, :button_payload, :button_url ].freeze

  # Steps arrive as an indexed tree (named by the steps Stimulus controller
  # on submit): workflow[steps][0][action], and for routers
  # workflow[steps][0][branches][1][steps][0][...]. Rebuilt wholesale.
  def save_steps
    @workflow.workflow_steps.destroy_all
    build_steps(params[:workflow][:steps], parent: nil, branch_index: nil)
  end

  def build_steps(steps_param, parent:, branch_index:)
    position = 0
    collection(steps_param).each do |raw|
      attrs = raw.permit(*STEP_FIELDS).to_h.compact_blank
      action = attrs.delete("action")
      next unless WorkflowStep::ACTIONS.include?(action)
      next if action == "router" && parent.present? # one nesting level

      if action == "router"
        branches = collection(raw[:branches])
        step = @workflow.workflow_steps.create!(
          position: position, action: "router", parent_step: parent, branch_index: branch_index,
          params: {
            "mode" => attrs["mode"] == "all_matches" ? "all_matches" : "first_match",
            "branches" => branches.map { |b| { "name" => b[:name].to_s, "segment_id" => b[:segment_id].presence } }
          }
        )
        branches.each_with_index do |branch, index|
          build_steps(branch[:steps], parent: step, branch_index: index)
        end
      else
        @workflow.workflow_steps.create!(position: position, action: action, params: attrs, parent_step: parent, branch_index: branch_index)
      end
      position += 1
    end
  end

  def collection(param)
    case param
    when ActionController::Parameters then param.values
    when Array then param
    else []
    end
  end
end
