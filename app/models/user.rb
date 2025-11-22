class User < ApplicationRecord
  # 관계(Associations) 정의
  # User는 여러 개의 Workout을 가질 수 있음 (has_many)
  has_many :workouts, dependent: :destroy
  
  # User는 여러 개의 DailyWorkout을 가질 수 있음
  has_many :daily_workouts, dependent: :destroy
  
  # User는 여러 개의 ShareCard를 가질 수 있음
  has_many :share_cards, dependent: :destroy
  
  # User는 여러 개의 Feedback을 가질 수 있음
  has_many :feedbacks, dependent: :destroy

  # 유효성 검사(Validations)
  validates :provider, presence: true
  validates :provider_user_id, presence: true
  validates :nickname, presence: true

  # provider와 provider_user_id의 조합은 유일해야 함 (소셜 로그인 중복 방지)
  validates :provider_user_id, uniqueness: { scope: :provider }
end
