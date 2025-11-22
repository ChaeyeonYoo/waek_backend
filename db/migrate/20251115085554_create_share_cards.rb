class CreateShareCards < ActiveRecord::Migration[7.1]
  def change
    create_table :share_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workout, null: false, foreign_key: true
      t.date :card_date, null: false                        # 카드에 표시되는 날짜
      t.string :frame_theme_key                             # 어떤 프레임/테마인지 식별
      t.string :image_url                                   # 완성된 카드 이미지 URL (MVP에서는 옵션)
      t.decimal :distance, precision: 10, scale: 2         # Workout에서 복사한 스냅샷 값 (미터 단위)
      t.integer :steps                                      # Workout에서 복사한 스냅샷 값
      t.integer :duration                                   # Workout에서 복사한 스냅샷 값 (초 단위)

      t.timestamps
    end

    # 날짜별 조회 성능 향상을 위한 인덱스
    add_index :share_cards, :card_date
    
    # 특정 유저의 특정 날짜 조회 성능 향상을 위한 복합 인덱스
    add_index :share_cards, [:user_id, :card_date]
  end
end
