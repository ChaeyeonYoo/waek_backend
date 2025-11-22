class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false                          # 피드백 내용 (필수)
      t.string :app_version                                 # 앱 버전 (선택사항)
      t.string :platform, null: false                       # 플랫폼 (예: "ios", "android")

      t.timestamps
    end
  end
end
