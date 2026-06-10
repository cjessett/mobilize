class CreateEmail < ActiveRecord::Migration[8.1]
  def change
    create_table :email_blasts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :access_scope, polymorphic: true, null: false
      t.references :segment, foreign_key: true
      t.string :name, null: false
      t.string :subject, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.timestamps
    end

    create_table :email_deliveries do |t|
      t.references :email_blast, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.datetime :opened_at
      t.string :error_message
      t.timestamps
    end
    add_index :email_deliveries, [ :email_blast_id, :person_id ], unique: true
  end
end
