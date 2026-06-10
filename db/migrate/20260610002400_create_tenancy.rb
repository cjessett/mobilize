class CreateTenancy < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :time_zone, null: false, default: "UTC"
      t.references :parent, foreign_key: { to_table: :organizations }
      t.timestamps
    end

    create_table :chapters do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone_number
      t.boolean :default, null: false, default: false
      t.timestamps
    end

    create_table :chapter_zip_codes do |t|
      t.references :chapter, null: false, foreign_key: true
      t.string :zip_code, null: false
      t.timestamps
    end
    add_index :chapter_zip_codes, [ :chapter_id, :zip_code ], unique: true

    create_table :people do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.string :address
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :preferred_language, null: false, default: "en"
      t.datetime :opted_out_sms_at
      t.datetime :unsubscribed_email_at
      t.boolean :do_not_call, null: false, default: false
      t.json :custom_field_values, null: false, default: {}
      t.timestamps
    end
    add_index :people, [ :organization_id, :phone ], unique: true, where: "phone IS NOT NULL"
    add_index :people, [ :organization_id, :email ]

    create_table :chapter_memberships do |t|
      t.references :chapter, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.boolean :primary, null: false, default: false
      t.timestamps
    end
    add_index :chapter_memberships, [ :person_id, :chapter_id ], unique: true
    add_index :chapter_memberships, :person_id, unique: true, where: '"primary" = TRUE', name: "index_chapter_memberships_one_primary_per_person"

    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :role, null: false, default: "organizer"
      t.references :access_scope, polymorphic: true, null: false
      t.timestamps
    end
    add_index :memberships, [ :user_id, :organization_id ], unique: true

    add_reference :users, :person, foreign_key: true
  end
end
