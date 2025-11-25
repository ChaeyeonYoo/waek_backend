# User 모델
# 소셜 로그인 사용자 정보를 관리합니다
class User < ApplicationRecord
  # 관계(Associations) 정의
  has_many :walks, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

  # 유효성 검사(Validations)
  validates :provider, presence: true, inclusion: { in: %w[kakao google apple] }
  validates :provider_id, presence: true
  validates :nickname, presence: true
  validates :profile_image_code, inclusion: { in: 0..4 }, allow_nil: true
  validates :token_version, presence: true, numericality: { greater_than_or_equal_to: 1 }

  # username 유효성 검사 (soft delete된 유저 제외)
  validates :username, allow_nil: true,
            format: { with: /\A[a-z0-9_]+\z/, message: "can only contain lowercase letters, numbers, and underscore" },
            length: { minimum: 3, maximum: 20, message: "must be 3~20 characters" }
  validate :username_unique_among_active_users

  # provider와 provider_id의 조합은 active 유저 중에서 유일해야 함 (soft delete된 유저 제외)
  validate :provider_id_unique_among_active_users

  # Soft delete 체크
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # 구독 상태 확인 메서드
  def is_expired?
    return true if !is_subscribed && !is_trial
    return true if is_subscribed && subscription_expires_at && subscription_expires_at < Time.current
    return true if is_trial && trial_expires_at && trial_expires_at < Time.current
    false
  end

  # 구독 타입 반환
  def subscription_type
    return 'paid' if is_subscribed && !is_expired?
    return 'trial' if is_trial && !is_expired?
    'none'
  end

  # 남은 일수 계산
  def days_left
    return 0 if is_expired?
    expires_at = is_subscribed ? subscription_expires_at : trial_expires_at
    return 0 unless expires_at
    ((expires_at - Time.current) / 1.day).ceil
  end

  # Soft delete 처리
  def soft_delete!
    update(deleted_at: Time.current)
  end

  # 로그인 시 last_login_at 업데이트
  def update_last_login!
    update(last_login_at: Time.current)
  end

  # 로그아웃 시 token_version 증가
  def increment_token_version!
    increment!(:token_version)
  end

  private

  # username이 active 유저 중에서 유일한지 확인
  def username_unique_among_active_users
    return if username.blank?
    return if deleted_at.present? # 이미 삭제된 유저는 체크 안 함

    # 자기 자신을 제외하고, active 유저 중 같은 username이 있는지 확인
    existing = User.active.where(username: username)
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:username, "has already been taken")
    end
  end

  # provider + provider_id 조합이 active 유저 중에서 유일한지 확인
  def provider_id_unique_among_active_users
    return if deleted_at.present? # 이미 삭제된 유저는 체크 안 함

    # 자기 자신을 제외하고, active 유저 중 같은 provider + provider_id가 있는지 확인
    existing = User.active.where(provider: provider, provider_id: provider_id)
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:provider_id, "has already been taken for this provider")
    end
  end
end
