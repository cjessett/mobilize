class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :access_scope, polymorphic: true, null: false
      t.references :host, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :location
      t.string :virtual_url
      t.integer :capacity
      t.timestamps
    end

    create_table :rsvps do |t|
      t.references :event, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :status, null: false, default: "yes"
      t.boolean :attended, null: false, default: false
      t.timestamps
    end
    add_index :rsvps, [ :event_id, :person_id ], unique: true
  end
end
