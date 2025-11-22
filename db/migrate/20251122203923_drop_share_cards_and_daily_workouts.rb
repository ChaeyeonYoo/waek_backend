class DropShareCardsAndDailyWorkouts < ActiveRecord::Migration[7.1]
  def up
    # Foreign key 제거
    remove_foreign_key :share_cards, :users if foreign_key_exists?(:share_cards, :users)
    remove_foreign_key :share_cards, :walks if foreign_key_exists?(:share_cards, :walks, column: "workout_id")
    remove_foreign_key :daily_workouts, :users if foreign_key_exists?(:daily_workouts, :users)
    
    # 테이블 삭제
    drop_table :share_cards if table_exists?(:share_cards)
    drop_table :daily_workouts if table_exists?(:daily_workouts)
  end

  def down
    # 역방향 마이그레이션 (필요시 복구)
    create_table :daily_workouts do |t|
      t.bigint :user_id, null: false
      t.date :date, null: false
      t.boolean :is_workout_goal_achieved, default: false, null: false
      t.boolean :has_walk_10min, default: false, null: false
      t.timestamps
    end
    add_index :daily_workouts, [:user_id, :date], unique: true
    add_foreign_key :daily_workouts, :users

    create_table :share_cards do |t|
      t.bigint :user_id, null: false
      t.bigint :workout_id, null: false
      t.date :card_date, null: false
      t.string :frame_theme_key
      t.string :image_url
      t.decimal :distance, precision: 10, scale: 2
      t.integer :steps
      t.integer :duration
      t.timestamps
    end
    add_index :share_cards, :card_date
    add_index :share_cards, [:user_id, :card_date]
    add_foreign_key :share_cards, :users
    add_foreign_key :share_cards, :walks, column: :workout_id
  end
end
