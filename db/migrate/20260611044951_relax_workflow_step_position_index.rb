class RelaxWorkflowStepPositionIndex < ActiveRecord::Migration[8.1]
  # Positions restart inside each router branch, so they're only unique per
  # (workflow, parent, branch). SQLite treats NULLs as distinct in unique
  # indexes, so a plain index serves top-level steps.
  def change
    remove_index :workflow_steps, [ :workflow_id, :position ], unique: true
    add_index :workflow_steps, [ :workflow_id, :parent_step_id, :branch_index, :position ]
  end
end
