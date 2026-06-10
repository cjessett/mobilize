# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_10_002400) do
  create_table "chapter_memberships", force: :cascade do |t|
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.integer "person_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_id"], name: "index_chapter_memberships_on_chapter_id"
    t.index ["person_id", "chapter_id"], name: "index_chapter_memberships_on_person_id_and_chapter_id", unique: true
    t.index ["person_id"], name: "index_chapter_memberships_on_person_id"
    t.index ["person_id"], name: "index_chapter_memberships_one_primary_per_person", unique: true, where: "\"primary\" = TRUE"
  end

  create_table "chapter_zip_codes", force: :cascade do |t|
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zip_code", null: false
    t.index ["chapter_id", "zip_code"], name: "index_chapter_zip_codes_on_chapter_id_and_zip_code", unique: true
    t.index ["chapter_id"], name: "index_chapter_zip_codes_on_chapter_id"
  end

  create_table "chapters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_chapters_on_organization_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.datetime "created_at", null: false
    t.integer "organization_id", null: false
    t.string "role", default: "organizer", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["access_scope_type", "access_scope_id"], name: "index_memberships_on_access_scope"
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "parent_id"
    t.string "slug", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_organizations_on_parent_id"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.json "custom_field_values", default: {}, null: false
    t.boolean "do_not_call", default: false, null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.datetime "opted_out_sms_at"
    t.integer "organization_id", null: false
    t.string "phone"
    t.string "preferred_language", default: "en", null: false
    t.string "state"
    t.datetime "unsubscribed_email_at"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["organization_id", "email"], name: "index_people_on_organization_id_and_email"
    t.index ["organization_id", "phone"], name: "index_people_on_organization_id_and_phone", unique: true, where: "phone IS NOT NULL"
    t.index ["organization_id"], name: "index_people_on_organization_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "person_id"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["person_id"], name: "index_users_on_person_id"
  end

  add_foreign_key "chapter_memberships", "chapters"
  add_foreign_key "chapter_memberships", "people"
  add_foreign_key "chapter_zip_codes", "chapters"
  add_foreign_key "chapters", "organizations"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "organizations", "organizations", column: "parent_id"
  add_foreign_key "people", "organizations"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "people"
end
