class AddGoalsToWorkflows < ActiveRecord::Migration[8.1]
  def change
    add_column :workflows, :goal_trigger, :string
    add_column :workflows, :goal_param, :string
  end
end
