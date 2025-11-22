class RefactorFeedbackModel < ActiveRecord::Migration[7.1]
  def change
    # platform → device_type으로 변경
    rename_column :feedbacks, :platform, :device_type
    
    # app_version은 그대로 유지
    # updated_at은 그대로 유지 (Rails 기본)
  end
end
