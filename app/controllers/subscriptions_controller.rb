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
  # ⚠️ 임시 구독 활성화 (iOS 테스트용, 추후 정식 API로 전환 예정)
  # 선택적으로 정식 API 파라미터(expires_at, transaction_id)를 받을 수 있음
  # 이미 구독 경험이 있는 경우에도 반영 가능 (연장/재구독)
  def activate_temp_subscription
    user = current_user
    current_time = Time.current
    
    # 업데이트 전 상태 저장 (로그/메시지용)
    was_already_subscribed = user.is_subscribed && user.subscription_expires_at && user.subscription_expires_at > current_time
    
    # expires_at이 제공되면 사용, 없으면 기본 30일
    expires_at_param = params[:expires_at]
    transaction_id = params[:transaction_id]
    platform = params[:platform] || 'ios'
    
    if expires_at_param
      begin
        subscription_expires_at = Time.zone.parse(expires_at_param)
      rescue ArgumentError
        render json: { error: 'expires_at 형식이 올바르지 않습니다 (ISO8601 형식 필요)' }, status: :bad_request
        return
      end
    else
      # 기본값: 30일
      # 이미 구독 중인 경우: 현재 만료일에서 30일 연장
      # 만료되었거나 구독 중이 아닌 경우: 오늘부터 30일
      if was_already_subscribed
        # 현재 구독이 유효한 경우: 만료일 연장
        subscription_expires_at = user.subscription_expires_at + 30.days
      else
        # 새로 구독하거나 만료된 경우: 오늘부터 30일
        subscription_expires_at = current_time + 30.days
      end
    end

    # subscribed_at 설정
    # 이미 구독 경험이 있고 현재 구독 중이면 기존 subscribed_at 유지
    # 새로 구독하거나 만료된 경우에만 현재 시간으로 설정
    if user.has_ever_subscribed && was_already_subscribed
      subscribed_at = user.subscribed_at || current_time
    else
      subscribed_at = current_time
    end

    # 로그 기록 (정식 API 사용 권장)
    if Rails.env.production?
      if expires_at_param && transaction_id
        Rails.logger.info "✅ [TEMP API] User #{user.id} (#{user.username}) used temp API with full params (ready for migration)"
      else
        action_type = was_already_subscribed ? 'extended' : 'activated'
        Rails.logger.warn "⚠️  [TEMP API] User #{user.id} (#{user.username}) used temp API to #{action_type} subscription (expires_at: #{expires_at_param.present?}, transaction_id: #{transaction_id.present?})"
      end
    else
      action_type = was_already_subscribed ? 'extend' : 'activate'
      Rails.logger.info "ℹ️  [TEMP API] User #{user.id} (#{user.username}) used temp API to #{action_type} subscription"
    end

    # 구독 정보 업데이트
    # has_ever_subscribed는 이미 true면 유지, false면 true로 설정
    update_params = {
      is_subscribed: true,
      subscribed_at: subscribed_at,
      subscription_expires_at: subscription_expires_at
    }
    update_params[:has_ever_subscribed] = true unless user.has_ever_subscribed

    user.update!(update_params)

    action_message = was_already_subscribed ? '구독이 연장되었습니다' : '구독이 활성화되었습니다'

    render json: {
      status: 'activated',
      message: action_message,
      is_subscribed: user.is_subscribed,
      subscription_expires_at: format_time(user.subscription_expires_at),
      days_left: user.days_left,
      has_ever_subscribed: user.has_ever_subscribed
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

