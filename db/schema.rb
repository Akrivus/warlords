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

ActiveRecord::Schema[8.1].define(version: 2026_03_22_200106) do
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

  create_table "card_definitions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "body", null: false
    t.string "card_type", default: "authored", null: false
    t.datetime "created_at", null: false
    t.string "faction_key"
    t.string "key", null: false
    t.json "metadata", default: {}, null: false
    t.string "portrait_key"
    t.json "response_a_effects", default: [], null: false
    t.string "response_a_follow_up_card_key"
    t.string "response_a_text", null: false
    t.json "response_b_effects", default: [], null: false
    t.string "response_b_follow_up_card_key"
    t.string "response_b_text", null: false
    t.string "scenario_key", null: false
    t.json "spawn_rules", default: {}, null: false
    t.string "speaker_key"
    t.string "speaker_name"
    t.string "speaker_type"
    t.json "tags", default: [], null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "weight", default: 0, null: false
    t.index ["scenario_key", "active"], name: "index_card_definitions_on_scenario_key_and_active"
    t.index ["scenario_key", "key"], name: "index_card_definitions_on_scenario_key_and_key", unique: true
  end

  create_table "event_logs", force: :cascade do |t|
    t.text "body"
    t.string "card_key"
    t.datetime "created_at", null: false
    t.integer "cycle_number"
    t.string "event_type", null: false
    t.integer "game_session_id", null: false
    t.datetime "occurred_at", null: false
    t.json "payload", default: {}, null: false
    t.integer "session_card_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id", "occurred_at"], name: "index_event_logs_on_game_session_id_and_occurred_at"
    t.index ["game_session_id"], name: "index_event_logs_on_game_session_id"
    t.index ["session_card_id"], name: "index_event_logs_on_session_card_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.json "context_state", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "current_card_id"
    t.integer "cycle_number", default: 1, null: false
    t.json "deck_state", default: {}, null: false
    t.datetime "ended_at"
    t.string "scenario_key", null: false
    t.string "seed"
    t.datetime "started_at"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["scenario_key"], name: "index_game_sessions_on_scenario_key"
    t.index ["status"], name: "index_game_sessions_on_status"
    t.index ["user_id"], name: "index_game_sessions_on_user_id"
  end

  create_table "session_cards", force: :cascade do |t|
    t.text "body", null: false
    t.integer "card_definition_id"
    t.string "chosen_response"
    t.datetime "created_at", null: false
    t.integer "cycle_number", null: false
    t.string "faction_key"
    t.string "fingerprint"
    t.integer "game_session_id", null: false
    t.json "generation_params", default: {}, null: false
    t.json "metadata", default: {}, null: false
    t.string "portrait_key"
    t.text "resolution_summary"
    t.json "response_a_effects", default: [], null: false
    t.string "response_a_follow_up_card_key"
    t.string "response_a_text", null: false
    t.json "response_b_effects", default: [], null: false
    t.string "response_b_follow_up_card_key"
    t.string "response_b_text", null: false
    t.integer "slot_index", null: false
    t.string "source_type", default: "card_definition", null: false
    t.string "speaker_key"
    t.string "speaker_name"
    t.string "speaker_type"
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["card_definition_id"], name: "index_session_cards_on_card_definition_id"
    t.index ["game_session_id", "cycle_number", "slot_index"], name: "idx_on_game_session_id_cycle_number_slot_index_5bf5be4fb1", unique: true
    t.index ["game_session_id", "status"], name: "index_session_cards_on_game_session_id_and_status"
    t.index ["game_session_id"], name: "index_session_cards_on_game_session_id"
  end

  create_table "user_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["provider", "uid"], name: "index_user_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_user_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_user_identities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "event_logs", "game_sessions"
  add_foreign_key "event_logs", "session_cards"
  add_foreign_key "game_sessions", "session_cards", column: "current_card_id"
  add_foreign_key "game_sessions", "users"
  add_foreign_key "session_cards", "card_definitions"
  add_foreign_key "session_cards", "game_sessions"
  add_foreign_key "user_identities", "users"
end
