class Feedback < ApplicationRecord
  # 관계(Associations) 정의
  # Feedback은 하나의 User에 속함 (belongs_to)
  belongs_to :user

  # 유효성 검사(Validations)
  validates :content, presence: true
  validates :platform, presence: true
end
