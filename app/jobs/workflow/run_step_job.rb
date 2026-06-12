class Workflow::RunStepJob < ApplicationJob
  queue_as :default

  def perform(run)
    return unless run.status == "running"
    return run.update!(status: "completed", finished_at: Time.current) unless run.workflow.enabled?

    step = run.current_step
    if step.nil?
      run.update!(status: "completed", finished_at: Time.current)
      return
    end

    resolver = Workflow::StepResolver.new(run)
    step.execute(run.person, run.context) unless step.wait? || step.router?
    record_execution(step, run)
    advance(run, resolver.next_step(step))
    return unless run.status == "running" && run.current_step_id

    if step.wait?
      Workflow::RunStepJob.set(wait: step.wait_duration).perform_later(run)
    else
      Workflow::RunStepJob.perform_later(run)
    end
  rescue => e
    run.update!(status: "failed", error_message: e.message)
    raise e
  end

  private

  def advance(run, next_step)
    if next_step
      run.update!(current_step_id: next_step.id, context: run.context)
    else
      run.update!(status: "completed", finished_at: Time.current, current_step_id: nil, context: run.context)
    end
  end

  def record_execution(step, run)
    WorkflowStepExecution.create!(workflow_step: step, workflow_run: run, person: run.person, executed_at: Time.current)
  end
end
