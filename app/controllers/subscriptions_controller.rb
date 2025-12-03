# Subscription (구독) 관련 API 컨트롤러
class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  # GET /me/subscription
  # 구독 상태 조회
  def show
    user = current_user

    response_data = {
      type: user.subscription_type,
      is_subscribed: user.is_subscribed,
      is_trial: user.is_trial,
      is_expired: user.is_expired?,
      has_used_trial: user.has_used_trial,
      has_ever_subscribed: user.has_ever_subscribed, # 한번이라도 구독한 경험 여부
      subscription_expires_at: format_time(user.subscription_expires_at),
      trial_expires_at: format_time(user.trial_expires_at),
      days_left: user.days_left
    }

    render json: response_data, status: :ok
  end

  # POST /me/subscription/trial
  # 무료체험 시작 (1회 한정)
  def start_trial
    user = current_user

    if user.has_used_trial
      render json: { error: '이미 무료체험을 사용했습니다' }, status: :bad_request
      return
    end

    if user.is_trial && !user.is_expired?
      render json: { error: '이미 무료체험 중입니다' }, status: :bad_request
      return
    end

    # 무료체험 시작 (7일)
    trial_started_at = Time.current
    trial_expires_at = trial_started_at + 7.days

    user.update!(
      is_trial: true,
      trial_started_at: trial_started_at,
      trial_expires_at: trial_expires_at,
      has_used_trial: true
    )

    head :no_content
  end

  # POST /me/subscription/temp
  # ⚠️ 임시 구독 활성화 (iOS 테스트용, 추후 제거 예정)
  def activate_temp_subscription
    user = current_user
    subscribed_at = Time.current
    subscription_expires_at = subscribed_at + 30.days

    user.update!(
      is_subscribed: true,
      subscribed_at: subscribed_at,
      subscription_expires_at: subscription_expires_at,
      has_ever_subscribed: true # 구독 경험 기록
    )

    render json: {
      status: 'activated',
      message: '임시 구독이 활성화되었습니다 (iOS 테스트용)',
      is_subscribed: user.is_subscribed,
      subscription_expires_at: format_time(user.subscription_expires_at),
      days_left: user.days_left
    }, status: :ok
  end

  # POST /me/subscription
  # iOS 결제 후 구독 활성화
  def create
    platform = params[:platform]
    transaction_id = params[:transaction_id]
    expires_at = params[:expires_at]
    auto_renew = params[:auto_renew] || true

    unless platform && transaction_id && expires_at
      render json: { error: 'platform, transaction_id, expires_at는 필수입니다' }, status: :bad_request
      return
    end

    # expires_at 파싱 (현재 시간대 기준)
    begin
      expires_at_time = Time.zone.parse(expires_at)
    rescue ArgumentError
      render json: { error: 'expires_at 형식이 올바르지 않습니다 (ISO8601 형식 필요)' }, status: :bad_request
      return
    end

    user = current_user
    subscribed_at = Time.current

    user.update!(
      is_subscribed: true,
      subscribed_at: subscribed_at,
      subscription_expires_at: expires_at_time,
      has_ever_subscribed: true # 구독 경험 기록
    )

    render json: {
      status: 'subscribed',
      subscription_expires_at: format_time(user.subscription_expires_at)
    }, status: :ok
  end

  # DELETE /me/subscription
  # 구독 해지 처리
  def destroy
    user = current_user

    unless user.is_subscribed
      render json: { error: '구독 중이 아닙니다' }, status: :bad_request
      return
    end

    # 구독 해지 (expires_at는 유지, is_subscribed만 false로)
    user.update!(is_subscribed: false)

    render json: {
      status: 'cancelled',
      expires_at: format_time(user.subscription_expires_at)
    }, status: :ok
  end
end

