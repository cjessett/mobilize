class CreateCrm < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_fields do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.string :field_type, null: false, default: "text"
      t.timestamps
    end
    add_index :custom_fields, [ :organization_id, :key ], unique: true

    create_table :tags do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :tags, [ :organization_id, :name ], unique: true

    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.timestamps
    end
    add_index :taggings, [ :tag_id, :person_id ], unique: true

    create_table :notes do |t|
      t.references :person, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end

    create_table :activities do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :kind, null: false
      t.references :subject, polymorphic: true
      t.json :data, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :activities, [ :person_id, :occurred_at ]

    create_table :segments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :access_scope, polymorphic: true, null: false
      t.string :name, null: false
      t.json :definition, null: false, default: {}
      t.timestamps
    end
  end
end
