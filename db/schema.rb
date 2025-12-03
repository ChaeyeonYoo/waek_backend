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

ActiveRecord::Schema[7.1].define(version: 2025_12_03_024603) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.string "app_version"
    t.string "device_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "nickname"
    t.integer "profile_image_code"
    t.string "provider", null: false
    t.string "provider_id"
    t.boolean "is_subscribed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "token_version", default: 1, null: false
    t.datetime "subscribed_at"
    t.datetime "subscription_expires_at"
    t.boolean "is_trial", default: false, null: false
    t.datetime "trial_started_at"
    t.datetime "trial_expires_at"
    t.boolean "has_used_trial", default: false, null: false
    t.datetime "last_login_at"
    t.datetime "deleted_at"
    t.boolean "has_ever_subscribed", default: false, null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["provider", "provider_id"], name: "index_users_on_provider_and_provider_id_where_not_deleted", unique: true, where: "(deleted_at IS NULL)"
    t.index ["username"], name: "index_users_on_username_where_not_deleted", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "walks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at", null: false
    t.integer "distance_meters"
    t.integer "step_count"
    t.integer "duration_seconds", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_key"
    t.string "status", default: "active", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_walks_on_deleted_at"
    t.index ["status"], name: "index_walks_on_status"
    t.index ["user_id", "started_at"], name: "index_walks_on_user_id_and_started_at"
    t.index ["user_id"], name: "index_walks_on_user_id"
  end

  add_foreign_key "feedbacks", "users"
  add_foreign_key "walks", "users"
end
