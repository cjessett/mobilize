class RelaxWorkflowTriggerColumns < ActiveRecord::Migration[8.1]
  # Triggers now live in workflow_triggers; the legacy columns remain only
  # for programmatic creation convenience and will be dropped later.
  def change
    change_column_null :workflows, :trigger, true
  end
end
