# Walk 모델 (이전 Workout)
# 산책 기록을 관리합니다
class Walk < ApplicationRecord
  # 관계(Associations) 정의
  belongs_to :user

  # 유효성 검사(Validations)
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validates :duration_seconds, presence: true, numericality: { greater_than: 0 }
  validates :distance_meters, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :step_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[active deleted] }
  
  # 종료 시간은 시작 시간보다 이후여야 함
  validate :ended_at_after_started_at

  # 기본 스코프
  scope :active, -> { where(status: 'active', deleted_at: nil) }
  scope :deleted, -> { where(status: 'deleted').or(where.not(deleted_at: nil)) }

  # photo_key를 기반으로 presigned GET URL 생성
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 1시간)
  # @return [String, nil] Presigned GET URL 또는 nil
  def photo_url(expires_in: 3600)
    return nil if photo_key.blank?
    S3PresignedUrlService.presigned_get_url(photo_key, expires_in: expires_in)
  end

  # 날짜 반환 (started_at 기준)
  def date
    started_at&.to_date
  end

  # Soft delete 처리
  def soft_delete!
    update(status: 'deleted', deleted_at: Time.current)
  end

  private

  def ended_at_after_started_at
    return unless started_at && ended_at
    
    if ended_at <= started_at
      errors.add(:ended_at, "종료 시간은 시작 시간보다 이후여야 합니다")
    end
  end
end

