class RenameProviderUserIdToProviderIdInUsers < ActiveRecord::Migration[7.1]
  def change
    # 인덱스 먼저 제거
    remove_index :users, name: "index_users_on_provider_and_provider_user_id"
    
    # 컬럼명 변경
    rename_column :users, :provider_user_id, :provider_id
    
    # 인덱스 다시 생성 (새 컬럼명으로)
    add_index :users, [:provider, :provider_id], unique: true, name: "index_users_on_provider_and_provider_id"
  end
end
