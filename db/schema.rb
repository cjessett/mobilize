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

ActiveRecord::Schema[8.1].define(version: 2026_06_11_052429) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.integer "organization_id", null: false
    t.integer "person_id", null: false
    t.integer "subject_id"
    t.string "subject_type"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_activities_on_organization_id"
    t.index ["person_id", "occurred_at"], name: "index_activities_on_person_id_and_occurred_at"
    t.index ["person_id"], name: "index_activities_on_person_id"
    t.index ["subject_type", "subject_id"], name: "index_activities_on_subject"
  end

  create_table "blasts", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "scheduled_at"
    t.integer "segment_id"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.string "texting_hours_mode", default: "queue", null: false
    t.datetime "updated_at", null: false
    t.json "variants", default: {}, null: false
    t.index ["access_scope_type", "access_scope_id"], name: "index_blasts_on_access_scope"
    t.index ["organization_id"], name: "index_blasts_on_organization_id"
    t.index ["segment_id"], name: "index_blasts_on_segment_id"
  end

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

  create_table "custom_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field_type", default: "text", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "key"], name: "index_custom_fields_on_organization_id_and_key", unique: true
    t.index ["organization_id"], name: "index_custom_fields_on_organization_id"
  end

  create_table "donations", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd", null: false
    t.datetime "donated_at", null: false
    t.integer "organization_id", null: false
    t.integer "person_id", null: false
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "donated_at"], name: "index_donations_on_organization_id_and_donated_at"
    t.index ["organization_id"], name: "index_donations_on_organization_id"
    t.index ["person_id"], name: "index_donations_on_person_id"
  end

  create_table "email_blasts", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "scheduled_at"
    t.integer "segment_id"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["access_scope_type", "access_scope_id"], name: "index_email_blasts_on_access_scope"
    t.index ["organization_id"], name: "index_email_blasts_on_organization_id"
    t.index ["segment_id"], name: "index_email_blasts_on_segment_id"
  end

  create_table "email_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "email_blast_id", null: false
    t.string "error_message"
    t.datetime "opened_at"
    t.integer "person_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["email_blast_id", "person_id"], name: "index_email_deliveries_on_email_blast_id_and_person_id", unique: true
    t.index ["email_blast_id"], name: "index_email_deliveries_on_email_blast_id"
    t.index ["person_id"], name: "index_email_deliveries_on_person_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_email_templates_on_organization_id"
  end

  create_table "event_co_hosts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "organization_id"], name: "index_event_co_hosts_on_event_id_and_organization_id", unique: true
    t.index ["event_id"], name: "index_event_co_hosts_on_event_id"
    t.index ["organization_id"], name: "index_event_co_hosts_on_organization_id"
  end

  create_table "event_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "event_id", null: false
    t.boolean "is_primary", default: false, null: false
    t.string "location"
    t.datetime "starts_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "virtual_url"
    t.index ["event_id"], name: "index_event_sessions_on_event_id"
    t.index ["starts_at"], name: "index_event_sessions_on_starts_at"
  end

  create_table "events", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.boolean "approved", default: true, null: false
    t.integer "capacity"
    t.string "cohost_code"
    t.integer "confirmation_days_before"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "event_type", default: "in_person", null: false
    t.integer "host_id"
    t.string "host_token"
    t.integer "invited_segment_id"
    t.string "location"
    t.integer "organization_id", null: false
    t.integer "recurrence_days_ahead", default: 30, null: false
    t.string "recurrence_frequency", default: "none", null: false
    t.date "recurrence_until"
    t.text "reminder_body"
    t.datetime "starts_at", null: false
    t.integer "submitted_by_id"
    t.string "tag_list"
    t.string "time_zone"
    t.string "title", null: false
    t.boolean "unlisted", default: false, null: false
    t.datetime "updated_at", null: false
    t.json "variants", default: {}, null: false
    t.string "virtual_url"
    t.index ["access_scope_type", "access_scope_id"], name: "index_events_on_access_scope"
    t.index ["cohost_code"], name: "index_events_on_cohost_code", unique: true
    t.index ["host_id"], name: "index_events_on_host_id"
    t.index ["host_token"], name: "index_events_on_host_token", unique: true
    t.index ["invited_segment_id"], name: "index_events_on_invited_segment_id"
    t.index ["organization_id"], name: "index_events_on_organization_id"
    t.index ["submitted_by_id"], name: "index_events_on_submitted_by_id"
  end

  create_table "form_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "form_id", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.integer "position", null: false
    t.boolean "required", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["form_id", "key"], name: "index_form_fields_on_form_id_and_key", unique: true
    t.index ["form_id"], name: "index_form_fields_on_form_id"
  end

  create_table "forms", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.integer "apply_tag_id"
    t.string "confirmation_message"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "goal"
    t.string "kind", default: "signup", null: false
    t.integer "organization_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["access_scope_type", "access_scope_id"], name: "index_forms_on_access_scope"
    t.index ["apply_tag_id"], name: "index_forms_on_apply_tag_id"
    t.index ["organization_id", "slug"], name: "index_forms_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_forms_on_organization_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organization_id", null: false
    t.text "reply_body"
    t.integer "tag_id"
    t.datetime "updated_at", null: false
    t.string "word", null: false
    t.index ["organization_id", "word"], name: "index_keywords_on_organization_id_and_word", unique: true
    t.index ["organization_id"], name: "index_keywords_on_organization_id"
    t.index ["tag_id"], name: "index_keywords_on_tag_id"
  end

  create_table "link_clicks", force: :cascade do |t|
    t.datetime "clicked_at", null: false
    t.datetime "created_at", null: false
    t.string "ip"
    t.integer "short_link_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["short_link_id"], name: "index_link_clicks_on_short_link_id"
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

  create_table "messages", force: :cascade do |t|
    t.integer "blast_id"
    t.text "body", null: false
    t.integer "chapter_id"
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.string "error_message"
    t.integer "organization_id", null: false
    t.integer "person_id", null: false
    t.string "provider_sid"
    t.datetime "send_after"
    t.datetime "sent_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["blast_id"], name: "index_messages_on_blast_id"
    t.index ["chapter_id"], name: "index_messages_on_chapter_id"
    t.index ["organization_id"], name: "index_messages_on_organization_id"
    t.index ["person_id", "created_at"], name: "index_messages_on_person_id_and_created_at"
    t.index ["person_id"], name: "index_messages_on_person_id"
    t.index ["provider_sid"], name: "index_messages_on_provider_sid"
  end

  create_table "notes", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "person_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["person_id"], name: "index_notes_on_person_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "parent_id"
    t.string "slug", null: false
    t.json "texting_days", default: [0, 1, 2, 3, 4, 5, 6], null: false
    t.integer "texting_hours_end", default: 21, null: false
    t.integer "texting_hours_start", default: 9, null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_token"
    t.index ["parent_id"], name: "index_organizations_on_parent_id"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["webhook_token"], name: "index_organizations_on_webhook_token", unique: true
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

  create_table "rsvps", force: :cascade do |t|
    t.boolean "attended", default: false, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "event_session_id", null: false
    t.integer "person_id", null: false
    t.string "status", default: "yes", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_rsvps_on_event_id"
    t.index ["event_session_id", "person_id"], name: "index_rsvps_on_event_session_id_and_person_id", unique: true
    t.index ["event_session_id"], name: "index_rsvps_on_event_session_id"
    t.index ["person_id"], name: "index_rsvps_on_person_id"
  end

  create_table "segments", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.datetime "created_at", null: false
    t.json "definition", default: {}, null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["access_scope_type", "access_scope_id"], name: "index_segments_on_access_scope"
    t.index ["organization_id"], name: "index_segments_on_organization_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "short_links", force: :cascade do |t|
    t.integer "blast_id"
    t.datetime "created_at", null: false
    t.string "destination_url", null: false
    t.integer "message_id"
    t.integer "organization_id", null: false
    t.integer "person_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["blast_id"], name: "index_short_links_on_blast_id"
    t.index ["message_id"], name: "index_short_links_on_message_id"
    t.index ["organization_id"], name: "index_short_links_on_organization_id"
    t.index ["person_id"], name: "index_short_links_on_person_id"
    t.index ["token"], name: "index_short_links_on_token", unique: true
  end

  create_table "sms_templates", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "event_id"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.json "variants", default: {}, null: false
    t.index ["event_id"], name: "index_sms_templates_on_event_id"
    t.index ["organization_id"], name: "index_sms_templates_on_organization_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.integer "form_id", null: false
    t.integer "person_id", null: false
    t.integer "source_blast_id"
    t.datetime "updated_at", null: false
    t.index ["form_id"], name: "index_submissions_on_form_id"
    t.index ["person_id"], name: "index_submissions_on_person_id"
    t.index ["source_blast_id"], name: "index_submissions_on_source_blast_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "person_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_taggings_on_person_id"
    t.index ["tag_id", "person_id"], name: "index_taggings_on_tag_id_and_person_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_tags_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_tags_on_organization_id"
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

  create_table "workflow_runs", force: :cascade do |t|
    t.json "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "current_position", default: 0, null: false
    t.integer "current_step_id"
    t.string "error_message"
    t.datetime "finished_at"
    t.datetime "goal_achieved_at"
    t.integer "person_id", null: false
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.integer "workflow_id", null: false
    t.index ["current_step_id"], name: "index_workflow_runs_on_current_step_id"
    t.index ["person_id"], name: "index_workflow_runs_on_person_id"
    t.index ["workflow_id", "person_id"], name: "index_workflow_runs_on_workflow_id_and_person_id", unique: true
    t.index ["workflow_id"], name: "index_workflow_runs_on_workflow_id"
  end

  create_table "workflow_step_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "executed_at", null: false
    t.integer "person_id", null: false
    t.datetime "updated_at", null: false
    t.integer "workflow_run_id", null: false
    t.integer "workflow_step_id", null: false
    t.index ["person_id"], name: "index_workflow_step_executions_on_person_id"
    t.index ["workflow_run_id"], name: "index_workflow_step_executions_on_workflow_run_id"
    t.index ["workflow_step_id"], name: "index_workflow_step_executions_on_workflow_step_id"
  end

  create_table "workflow_steps", force: :cascade do |t|
    t.string "action", null: false
    t.integer "branch_index"
    t.datetime "created_at", null: false
    t.json "params", default: {}, null: false
    t.integer "parent_step_id"
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.integer "workflow_id", null: false
    t.index ["parent_step_id"], name: "index_workflow_steps_on_parent_step_id"
    t.index ["workflow_id", "parent_step_id", "branch_index", "position"], name: "idx_on_workflow_id_parent_step_id_branch_index_posi_006d65a797"
    t.index ["workflow_id"], name: "index_workflow_steps_on_workflow_id"
  end

  create_table "workflow_triggers", force: :cascade do |t|
    t.json "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "param"
    t.string "trigger", null: false
    t.datetime "updated_at", null: false
    t.integer "workflow_id", null: false
    t.index ["trigger"], name: "index_workflow_triggers_on_trigger"
    t.index ["workflow_id"], name: "index_workflow_triggers_on_workflow_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.integer "access_scope_id", null: false
    t.string "access_scope_type", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "goal_param"
    t.string "goal_trigger"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.string "trigger"
    t.string "trigger_param"
    t.datetime "updated_at", null: false
    t.index ["access_scope_type", "access_scope_id"], name: "index_workflows_on_access_scope"
    t.index ["organization_id", "trigger"], name: "index_workflows_on_organization_id_and_trigger"
    t.index ["organization_id"], name: "index_workflows_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "organizations"
  add_foreign_key "activities", "people"
  add_foreign_key "blasts", "organizations"
  add_foreign_key "blasts", "segments"
  add_foreign_key "chapter_memberships", "chapters"
  add_foreign_key "chapter_memberships", "people"
  add_foreign_key "chapter_zip_codes", "chapters"
  add_foreign_key "chapters", "organizations"
  add_foreign_key "custom_fields", "organizations"
  add_foreign_key "donations", "organizations"
  add_foreign_key "donations", "people"
  add_foreign_key "email_blasts", "organizations"
  add_foreign_key "email_blasts", "segments"
  add_foreign_key "email_deliveries", "email_blasts"
  add_foreign_key "email_deliveries", "people"
  add_foreign_key "email_templates", "organizations"
  add_foreign_key "event_co_hosts", "events"
  add_foreign_key "event_co_hosts", "organizations"
  add_foreign_key "event_sessions", "events"
  add_foreign_key "events", "organizations"
  add_foreign_key "events", "people", column: "submitted_by_id"
  add_foreign_key "events", "segments", column: "invited_segment_id"
  add_foreign_key "events", "users", column: "host_id"
  add_foreign_key "form_fields", "forms"
  add_foreign_key "forms", "organizations"
  add_foreign_key "forms", "tags", column: "apply_tag_id"
  add_foreign_key "keywords", "organizations"
  add_foreign_key "keywords", "tags"
  add_foreign_key "link_clicks", "short_links"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "blasts"
  add_foreign_key "messages", "chapters"
  add_foreign_key "messages", "organizations"
  add_foreign_key "messages", "people"
  add_foreign_key "notes", "people"
  add_foreign_key "notes", "users"
  add_foreign_key "organizations", "organizations", column: "parent_id"
  add_foreign_key "people", "organizations"
  add_foreign_key "rsvps", "event_sessions"
  add_foreign_key "rsvps", "events"
  add_foreign_key "rsvps", "people"
  add_foreign_key "segments", "organizations"
  add_foreign_key "sessions", "users"
  add_foreign_key "short_links", "blasts"
  add_foreign_key "short_links", "messages"
  add_foreign_key "short_links", "organizations"
  add_foreign_key "short_links", "people"
  add_foreign_key "sms_templates", "events"
  add_foreign_key "sms_templates", "organizations"
  add_foreign_key "submissions", "forms"
  add_foreign_key "submissions", "people"
  add_foreign_key "taggings", "people"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tags", "organizations"
  add_foreign_key "users", "people"
  add_foreign_key "workflow_runs", "people"
  add_foreign_key "workflow_runs", "workflow_steps", column: "current_step_id"
  add_foreign_key "workflow_runs", "workflows"
  add_foreign_key "workflow_step_executions", "people"
  add_foreign_key "workflow_step_executions", "workflow_runs"
  add_foreign_key "workflow_step_executions", "workflow_steps"
  add_foreign_key "workflow_steps", "workflow_steps", column: "parent_step_id"
  add_foreign_key "workflow_steps", "workflows"
  add_foreign_key "workflow_triggers", "workflows"
  add_foreign_key "workflows", "organizations"
end
