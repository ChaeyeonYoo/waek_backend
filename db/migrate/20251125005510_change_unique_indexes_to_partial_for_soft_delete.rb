class ChangeUniqueIndexesToPartialForSoftDelete < ActiveRecord::Migration[7.1]
  def up
    # 기존 unique index 제거
    if index_exists?(:users, :username, name: "index_users_on_username")
      remove_index :users, name: "index_users_on_username"
    end
    
    if index_exists?(:users, [:provider, :provider_id], name: "index_users_on_provider_and_provider_id")
      remove_index :users, name: "index_users_on_provider_and_provider_id"
    end

    # Partial unique index 추가 (deleted_at이 NULL인 경우만 unique)
    # username은 active 유저(deleted_at이 NULL) 중에서만 유일해야 함
    add_index :users, :username, unique: true, where: "deleted_at IS NULL", name: "index_users_on_username_where_not_deleted"
    
    # provider + provider_id 조합도 active 유저 중에서만 유일해야 함
    add_index :users, [:provider, :provider_id], unique: true, where: "deleted_at IS NULL", name: "index_users_on_provider_and_provider_id_where_not_deleted"
  end

  def down
    # 역방향 마이그레이션
    if index_exists?(:users, :username, name: "index_users_on_username_where_not_deleted")
      remove_index :users, name: "index_users_on_username_where_not_deleted"
    end
    
    if index_exists?(:users, [:provider, :provider_id], name: "index_users_on_provider_and_provider_id_where_not_deleted")
      remove_index :users, name: "index_users_on_provider_and_provider_id_where_not_deleted"
    end

    # 기존 index 복원
    add_index :users, :username, unique: true
    add_index :users, [:provider, :provider_id], unique: true
  end
end
