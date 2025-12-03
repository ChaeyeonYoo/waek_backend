class AddHasEverSubscribedToUsers < ActiveRecord::Migration[7.1]
  def change
    # 한번이라도 구독한 경험이 있는지 추적하는 필드
    add_column :users, :has_ever_subscribed, :boolean, default: false, null: false
    
    # 기존에 구독 중이거나 과거에 구독했던 유저들을 true로 설정
    # subscribed_at이 있으면 과거에 구독한 경험이 있다고 간주
    execute <<-SQL
      UPDATE users
      SET has_ever_subscribed = true
      WHERE subscribed_at IS NOT NULL OR is_subscribed = true;
    SQL
  end
end
