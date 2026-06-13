class AddCostToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :cost_microcents, :bigint
    add_column :messages, :provider_cost_microcents, :bigint
    add_column :messages, :num_segments, :integer
  end
end
