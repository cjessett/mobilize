class AddTextingHours < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :texting_hours_start, :integer, null: false, default: 9
    add_column :organizations, :texting_hours_end, :integer, null: false, default: 21
    add_column :organizations, :texting_days, :json, null: false, default: [ 0, 1, 2, 3, 4, 5, 6 ]
    add_column :messages, :send_after, :datetime
    add_column :blasts, :texting_hours_mode, :string, null: false, default: "queue"
  end
end
