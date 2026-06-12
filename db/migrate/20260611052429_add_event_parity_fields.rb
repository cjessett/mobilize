class AddEventParityFields < ActiveRecord::Migration[8.1]
  def change
    change_table :events do |t|
      t.string :recurrence_frequency, null: false, default: "none"
      t.date :recurrence_until
      t.integer :recurrence_days_ahead, null: false, default: 30
      t.boolean :unlisted, null: false, default: false
      t.boolean :approved, null: false, default: true
      t.string :tag_list
      t.references :invited_segment, foreign_key: { to_table: :segments }
      t.string :time_zone
      t.text :reminder_body
      t.json :variants, null: false, default: {}
      t.integer :confirmation_days_before
      t.string :host_token
      t.string :cohost_code
      t.references :submitted_by, foreign_key: { to_table: :people }
    end
    add_index :events, :host_token, unique: true
    add_index :events, :cohost_code, unique: true

    add_column :rsvps, :confirmed_at, :datetime

    create_table :event_co_hosts do |t|
      t.references :event, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
    add_index :event_co_hosts, [ :event_id, :organization_id ], unique: true
  end
end
