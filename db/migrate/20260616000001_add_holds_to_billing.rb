class AddHoldsToBilling < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :held_microcents, :bigint, default: 0, null: false
    add_column :messages, :hold_microcents, :bigint
  end
end
