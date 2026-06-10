class WorkflowsController < ApplicationController
  before_action :set_workflow, only: [ :show, :edit, :update, :destroy, :toggle ]

  def index
    @workflows = Workflow.visible_to(current_membership).order(:name).includes(:workflow_steps)
  end

  def show
    @runs = @workflow.workflow_runs.order(created_at: :desc).limit(50).includes(:person)
  end

  def new
    @workflow = current_organization.workflows.new(access_scope: current_organization)
  end

  def create
    @workflow = current_organization.workflows.new(workflow_attributes)
    if @workflow.save
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
    permitted = params.require(:workflow).permit(:name, :trigger, :trigger_param, :access_scope_gid)
    scope = case permitted.delete(:access_scope_gid)
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
    permitted.merge(access_scope: scope)
  end

  def save_steps
    steps = Array(params[:workflow][:steps]).map { |s| s.permit(:action, :body, :subject, :tag_name, :duration_minutes, :email).to_h.compact_blank }
    steps = steps.select { |s| WorkflowStep::ACTIONS.include?(s["action"]) }
    @workflow.workflow_steps.destroy_all
    steps.each_with_index do |step, index|
      action = step.delete("action")
      @workflow.workflow_steps.create!(position: index, action: action, params: step)
    end
  end
end
