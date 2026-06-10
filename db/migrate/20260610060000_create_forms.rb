class CreateForms < ActiveRecord::Migration[8.1]
  def change
    create_table :forms do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :access_scope, polymorphic: true, null: false
      t.references :apply_tag, foreign_key: { to_table: :tags }
      t.string :kind, null: false, default: "signup"
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :goal
      t.string :confirmation_message
      t.timestamps
    end
    add_index :forms, [ :organization_id, :slug ], unique: true

    create_table :form_fields do |t|
      t.references :form, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :key, null: false
      t.string :label, null: false
      t.boolean :required, null: false, default: false
      t.timestamps
    end
    add_index :form_fields, [ :form_id, :key ], unique: true

    create_table :submissions do |t|
      t.references :form, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.json :data, null: false, default: {}
      t.timestamps
    end
  end
end
