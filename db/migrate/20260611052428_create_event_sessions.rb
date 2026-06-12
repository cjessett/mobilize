class CreateEventSessions < ActiveRecord::Migration[8.1]
  def up
    create_table :event_sessions do |t|
      t.references :event, null: false, foreign_key: true
      t.string :title
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :location
      t.string :virtual_url
      t.boolean :is_primary, null: false, default: false

      t.timestamps
    end
    add_index :event_sessions, :starts_at

    # Every existing event becomes a single-session event.
    execute <<~SQL
      INSERT INTO event_sessions (event_id, starts_at, ends_at, is_primary, created_at, updated_at)
      SELECT id, starts_at, ends_at, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM events
    SQL

    add_reference :rsvps, :event_session, foreign_key: true
    execute <<~SQL
      UPDATE rsvps SET event_session_id = (
        SELECT es.id FROM event_sessions es
        WHERE es.event_id = rsvps.event_id AND es.is_primary = 1
      )
    SQL
    change_column_null :rsvps, :event_session_id, false

    # One RSVP per person per session (was per event).
    remove_index :rsvps, [ :event_id, :person_id ], unique: true
    add_index :rsvps, [ :event_session_id, :person_id ], unique: true
  end

  def down
    remove_index :rsvps, [ :event_session_id, :person_id ], unique: true
    add_index :rsvps, [ :event_id, :person_id ], unique: true
    remove_reference :rsvps, :event_session
    drop_table :event_sessions
  end
end
