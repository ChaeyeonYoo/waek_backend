class ShareCard < ApplicationRecord
  # 관계(Associations) 정의
  # ShareCard는 하나의 User에 속함 (belongs_to)
  belongs_to :user
  
  # ShareCard는 하나의 Workout에 속함 (belongs_to)
  belongs_to :workout

  # 유효성 검사(Validations)
  validates :card_date, presence: true
end
