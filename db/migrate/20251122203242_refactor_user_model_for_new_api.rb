class RefactorUserModelForNewApi < ActiveRecord::Migration[7.1]
  def change
    # provider를 integer에서 string으로 변경
    change_column :users, :provider, :string, null: false
    
    # login_id → username으로 변경
    rename_column :users, :login_id, :username
    
    # profile_image_key → profile_image_code로 변경
    rename_column :users, :profile_image_key, :profile_image_code
    
    # is_premium → is_subscribed로 변경
    rename_column :users, :is_premium, :is_subscribed
    
    # social_email 제거 (필요 없음)
    remove_column :users, :social_email, :string
    
    # 새로운 필드 추가
    add_column :users, :token_version, :integer, default: 1, null: false
    add_column :users, :subscribed_at, :datetime, null: true
    add_column :users, :subscription_expires_at, :datetime, null: true
    add_column :users, :is_trial, :boolean, default: false, null: false
    add_column :users, :trial_started_at, :datetime, null: true
    add_column :users, :trial_expires_at, :datetime, null: true
    add_column :users, :has_used_trial, :boolean, default: false, null: false
    add_column :users, :last_login_at, :datetime, null: true
    add_column :users, :deleted_at, :datetime, null: true
    
    # 인덱스 추가
    add_index :users, :username, unique: true
    add_index :users, :deleted_at
  end
end
