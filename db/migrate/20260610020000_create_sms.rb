class CreateSms < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.references :chapter, foreign_key: true
      t.references :blast, foreign_key: true
      t.string :direction, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "pending"
      t.string :provider_sid
      t.string :error_message
      t.datetime :sent_at
      t.timestamps
    end
    add_index :messages, [ :person_id, :created_at ]
    add_index :messages, :provider_sid

    create_table :sms_templates do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.text :body, null: false
      t.timestamps
    end

    create_table :keywords do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :word, null: false
      t.references :tag, foreign_key: true
      t.text :reply_body
      t.timestamps
    end
    add_index :keywords, [ :organization_id, :word ], unique: true

    create_table :blasts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :access_scope, polymorphic: true, null: false
      t.references :segment, foreign_key: true
      t.string :name, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.timestamps
    end
  end
end
