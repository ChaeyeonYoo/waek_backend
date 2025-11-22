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

ActiveRecord::Schema[7.1].define(version: 2025_11_15_085555) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "daily_workouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.boolean "is_workout_goal_achieved", default: false, null: false
    t.boolean "has_walk_10min", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_daily_workouts_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_daily_workouts_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.string "app_version"
    t.string "platform", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "share_cards", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workout_id", null: false
    t.date "card_date", null: false
    t.string "frame_theme_key"
    t.string "image_url"
    t.decimal "distance", precision: 10, scale: 2
    t.integer "steps"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_date"], name: "index_share_cards_on_card_date"
    t.index ["user_id", "card_date"], name: "index_share_cards_on_user_id_and_card_date"
    t.index ["user_id"], name: "index_share_cards_on_user_id"
    t.index ["workout_id"], name: "index_share_cards_on_workout_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "login_id"
    t.string "nickname"
    t.integer "profile_image_key"
    t.integer "provider", null: false
    t.string "provider_user_id"
    t.string "social_email"
    t.boolean "is_premium", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_user_id"], name: "index_users_on_provider_and_provider_user_id", unique: true
  end

  create_table "workouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "workout_date", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at", null: false
    t.decimal "distance", precision: 10, scale: 2
    t.integer "steps"
    t.integer "duration", null: false
    t.decimal "calories", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "workout_date"], name: "index_workouts_on_user_id_and_workout_date"
    t.index ["user_id"], name: "index_workouts_on_user_id"
    t.index ["workout_date"], name: "index_workouts_on_workout_date"
  end

  add_foreign_key "daily_workouts", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "share_cards", "users"
  add_foreign_key "share_cards", "workouts"
  add_foreign_key "workouts", "users"
end
