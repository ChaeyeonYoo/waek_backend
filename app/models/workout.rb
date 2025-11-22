class Workout < ApplicationRecord
  # 관계(Associations) 정의
  # Workout은 하나의 User에 속함 (belongs_to)
  belongs_to :user
  
  # Workout은 여러 개의 ShareCard를 가질 수 있음 (같은 운동 결과를 여러 카드로 저장 가능)
  has_many :share_cards, dependent: :destroy

  # 유효성 검사(Validations)
  validates :workout_date, presence: true
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  
  # 종료 시간은 시작 시간보다 이후여야 함
  validate :ended_at_after_started_at

  # s3_key를 기반으로 presigned GET URL 생성
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 1시간)
  # @return [String, nil] Presigned GET URL 또는 nil
  def image_url(expires_in: 3600)
    return nil if s3_key.blank?
    S3PresignedUrlService.presigned_get_url(s3_key, expires_in: expires_in)
  end

  private

  def ended_at_after_started_at
    return unless started_at && ended_at
    
    if ended_at <= started_at
      errors.add(:ended_at, "종료 시간은 시작 시간보다 이후여야 합니다")
    end
  end
end
