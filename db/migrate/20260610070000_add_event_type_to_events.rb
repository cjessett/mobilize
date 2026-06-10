class AddEventTypeToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :event_type, :string, null: false, default: "in_person"
  end
end
