class ChangeDistanceMetersToIntegerInWalks < ActiveRecord::Migration[7.1]
  def up
    # distance_meters를 decimal에서 integer로 변경
    # ROUND를 사용하여 안전하게 변환
    change_column :walks, :distance_meters, :integer, using: 'ROUND(distance_meters)::integer'
  end

  def down
    # 역방향: integer에서 decimal로 복원
    change_column :walks, :distance_meters, :decimal, precision: 10, scale: 2
  end
end
