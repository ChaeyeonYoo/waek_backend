class ChangeImageUrlToS3KeyInWorkouts < ActiveRecord::Migration[7.1]
  def change
    # image_url 컬럼 제거하고 s3_key 추가
    # 기존 데이터가 있다면 마이그레이션 전에 백업 필요
    remove_column :workouts, :image_url, :string
    add_column :workouts, :s3_key, :string
  end
end
