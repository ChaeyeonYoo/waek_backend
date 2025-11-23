# Walk 모델 (이전 Workout)
# 산책 기록을 관리합니다
#
# 중요 사항:
# - photo_key 컬럼에는 S3 객체의 키만 저장됩니다 (예: "workouts/1234567890_abc123_walk.jpg")
# - 영구적인 public URL은 저장하지 않습니다 (보안 및 프라이버시)
# - photo_url 메서드는 동적으로 presigned GET URL을 생성합니다 (만료 시간: 1시간)
# - 모든 S3 객체는 private로 유지되며, presigned URL을 통해서만 접근 가능합니다
#
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
  # 
  # DB에 저장된 photo_key(S3 키)를 사용하여 임시 다운로드 URL을 생성합니다.
  # 이 URL은 만료 시간(기본 1시간)이 지나면 더 이상 사용할 수 없습니다.
  #
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 3600 = 1시간)
  # @return [String, nil] Presigned GET URL 또는 nil (photo_key가 없는 경우)
  #
  # 사용 예시:
  #   walk.photo_url  # => "https://waek-photo-bucket.s3.ap-northeast-2.amazonaws.com/..."
  #   walk.photo_url(expires_in: 7200)  # => 2시간 유효한 URL
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

