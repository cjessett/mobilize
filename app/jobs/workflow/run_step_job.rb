class Workflow::RunStepJob < ApplicationJob
  queue_as :default

  def perform(run)
    return unless run.status == "running"
    return run.update!(status: "completed", finished_at: Time.current) unless run.workflow.enabled?

    step = run.workflow.workflow_steps.find_by(position: run.current_position)
    if step.nil?
      run.update!(status: "completed", finished_at: Time.current)
      return
    end

    if step.wait?
      run.update!(current_position: run.current_position + 1)
      Workflow::RunStepJob.set(wait: step.wait_duration).perform_later(run)
    else
      step.execute(run.person)
      run.update!(current_position: run.current_position + 1)
      Workflow::RunStepJob.perform_later(run)
    end
  rescue => e
    run.update!(status: "failed", error_message: e.message)
    raise e
  end
end
