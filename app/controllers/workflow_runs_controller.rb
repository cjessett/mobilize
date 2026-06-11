# Removing a run frees the one-run-per-person constraint so the person can
# re-enroll the next time the workflow's trigger fires.
class WorkflowRunsController < ApplicationController
  def destroy
    run = WorkflowRun.joins(:workflow).where(workflows: { organization_id: current_organization.id }).find(params[:id])
    person = run.person
    run.destroy
    redirect_back fallback_location: person, notice: "Removed from \"#{run.workflow.name}\" — they can be enrolled again."
  end
end
