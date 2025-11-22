class CreateWorkouts < ActiveRecord::Migration[7.1]
  def change
    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.date :workout_date, null: false                    # 날짜 단위 통계용 (YYYY-MM-DD)
      t.datetime :started_at, null: false                  # 산책 시작 시간
      t.datetime :ended_at, null: false                    # 산책 종료 시간
      t.decimal :distance, precision: 10, scale: 2         # 거리 (미터 단위, precision: 전체 자릿수, scale: 소수점 자릿수)
      t.integer :steps                                     # 걸음수
      t.integer :duration, null: false                     # 지속 시간 (초 단위)
      t.decimal :calories, precision: 8, scale: 2          # 칼로리

      t.timestamps
    end

    # 날짜별 조회 성능 향상을 위한 인덱스
    add_index :workouts, :workout_date
    
    # 특정 유저의 특정 날짜 조회 성능 향상을 위한 복합 인덱스
    add_index :workouts, [:user_id, :workout_date]
  end
end
