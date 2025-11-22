class CreateDailyWorkouts < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false                              # 하루 기준 (YYYY-MM-DD)
      t.boolean :is_workout_goal_achieved, default: false, null: false  # 하루 목표 달성 여부
      t.boolean :has_walk_10min, default: false, null: false            # "10분 이상 산책" 여부 (도장용)

      t.timestamps
    end

    # 하루에 한 줄만 존재하도록 하는 unique 인덱스
    # (user_id, date) 조합이 유일해야 함
    add_index :daily_workouts, [:user_id, :date], unique: true
  end
end
