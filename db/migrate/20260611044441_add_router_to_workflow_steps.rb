class AddRouterToWorkflowSteps < ActiveRecord::Migration[8.1]
  def change
    add_reference :workflow_steps, :parent_step, foreign_key: { to_table: :workflow_steps }
    add_column :workflow_steps, :branch_index, :integer
    add_reference :workflow_runs, :current_step, foreign_key: { to_table: :workflow_steps }

    reversible do |dir|
      dir.up do
        # In-flight runs resolve their position cursor to a step-id cursor.
        execute <<~SQL
          UPDATE workflow_runs
          SET current_step_id = (
            SELECT ws.id FROM workflow_steps ws
            WHERE ws.workflow_id = workflow_runs.workflow_id AND ws.position = workflow_runs.current_position
          )
          WHERE status = 'running'
        SQL
      end
    end
  end
end
