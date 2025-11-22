class RenameWorkoutsToWalks < ActiveRecord::Migration[7.1]
  def up
    # workouts 테이블을 walks로 이름 변경
    rename_table :workouts, :walks
    
    # 컬럼명 변경
    rename_column :walks, :distance, :distance_meters
    rename_column :walks, :steps, :step_count
    rename_column :walks, :duration, :duration_seconds
    rename_column :walks, :s3_key, :photo_key
    
    # 불필요한 컬럼 제거
    remove_column :walks, :workout_date, :date
    remove_column :walks, :calories, :decimal
    
    # 새로운 필드 추가
    add_column :walks, :status, :string, default: 'active', null: false
    add_column :walks, :deleted_at, :datetime, null: true
    
    # 인덱스 변경
    remove_index :walks, name: "index_workouts_on_user_id_and_workout_date" if index_exists?(:walks, [:user_id, :workout_date], name: "index_workouts_on_user_id_and_workout_date")
    remove_index :walks, name: "index_workouts_on_workout_date" if index_exists?(:walks, :workout_date, name: "index_workouts_on_workout_date")
    add_index :walks, :status
    add_index :walks, :deleted_at
    add_index :walks, [:user_id, :started_at]
  end
  
  def down
    # 역방향 마이그레이션
    remove_index :walks, :status if index_exists?(:walks, :status)
    remove_index :walks, :deleted_at if index_exists?(:walks, :deleted_at)
    remove_index :walks, [:user_id, :started_at] if index_exists?(:walks, [:user_id, :started_at])
    
    remove_column :walks, :status, :string
    remove_column :walks, :deleted_at, :datetime
    
    add_column :walks, :workout_date, :date
    add_column :walks, :calories, :decimal, precision: 8, scale: 2
    
    rename_column :walks, :distance_meters, :distance
    rename_column :walks, :step_count, :steps
    rename_column :walks, :duration_seconds, :duration
    rename_column :walks, :photo_key, :s3_key
    
    rename_table :walks, :workouts
  end
end
