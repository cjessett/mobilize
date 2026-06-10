class CreateWorkflows < ActiveRecord::Migration[8.1]
  def change
    create_table :workflows do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :access_scope, polymorphic: true, null: false
      t.string :name, null: false
      t.string :trigger, null: false
      t.string :trigger_param
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :workflows, [ :organization_id, :trigger ]

    create_table :workflow_steps do |t|
      t.references :workflow, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :action, null: false
      t.json :params, null: false, default: {}
      t.timestamps
    end
    add_index :workflow_steps, [ :workflow_id, :position ], unique: true

    create_table :workflow_runs do |t|
      t.references :workflow, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :status, null: false, default: "running"
      t.integer :current_position, null: false, default: 0
      t.string :error_message
      t.datetime :finished_at
      t.timestamps
    end
  end
end
