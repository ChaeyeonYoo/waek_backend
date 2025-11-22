class DailyWorkout < ApplicationRecord
  # 관계(Associations) 정의
  # DailyWorkout은 하나의 User에 속함 (belongs_to)
  belongs_to :user

  # 유효성 검사(Validations)
  validates :date, presence: true
  
  # (user_id, date) 조합은 유일해야 함 - 하루에 한 줄만 존재
  validates :date, uniqueness: { scope: :user_id }
end
