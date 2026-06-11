class CreateWorkflowTriggers < ActiveRecord::Migration[8.1]
  def up
    create_table :workflow_triggers do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :trigger, null: false
      t.string :param
      t.json :config, null: false, default: {}

      t.timestamps
    end
    add_index :workflow_triggers, :trigger

    execute <<~SQL
      INSERT INTO workflow_triggers (workflow_id, trigger, param, config, created_at, updated_at)
      SELECT id, trigger, trigger_param, '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM workflows WHERE trigger IS NOT NULL AND trigger != ''
    SQL

    # One run per person per workflow: keep the newest of any duplicates.
    execute <<~SQL
      DELETE FROM workflow_runs WHERE id NOT IN (
        SELECT MAX(id) FROM workflow_runs GROUP BY workflow_id, person_id
      )
    SQL
    add_index :workflow_runs, [ :workflow_id, :person_id ], unique: true
    add_column :workflow_runs, :goal_achieved_at, :datetime
    add_column :workflow_runs, :context, :json, null: false, default: {}

    create_table :workflow_step_executions do |t|
      t.references :workflow_step, null: false, foreign_key: true
      t.references :workflow_run, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.datetime :executed_at, null: false

      t.timestamps
    end
  end

  def down
    drop_table :workflow_step_executions
    remove_column :workflow_runs, :context
    remove_column :workflow_runs, :goal_achieved_at
    remove_index :workflow_runs, [ :workflow_id, :person_id ]
    drop_table :workflow_triggers
  end
end
