# Feedback 모델
# 사용자 피드백을 관리합니다
class Feedback < ApplicationRecord
  # 관계(Associations) 정의
  belongs_to :user

  # 유효성 검사(Validations)
  validates :content, presence: true
  validates :device_type, presence: true, inclusion: { in: %w[ios android web] }
  validates :app_version, presence: true
end
