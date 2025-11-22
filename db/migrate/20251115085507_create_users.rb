class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :login_id                               # 로그인 아이디
      t.string :nickname                               # 사용자가 설정한 닉네임
      t.integer :profile_image_key                     # 프로필 사진 키 번호 (미리 제공된 사진 중 선택)
      t.integer :provider, null: false                 # 소셜 로그인 제공자 (1: apple, 2: kakao, 3: google)
      t.string :provider_user_id                       # 소셜 로그인 제공자에서 받은 유저 ID
      t.string :social_email                           # 소셜 로그인 이메일
      t.boolean :is_premium, default: false, null: false  # 프리미엄 여부, 기본값은 false

      t.timestamps
    end

    # 소셜 로그인 조회 성능 향상을 위한 복합 인덱스
    # provider와 provider_user_id로 유저를 찾을 때 빠르게 조회하기 위해
    add_index :users, [:provider, :provider_user_id], unique: true
  end
end
