# Feedback 관련 API 컨트롤러
class FeedbacksController < ApplicationController
  before_action :authenticate_user!, except: [:admin_index]

  # POST /feedbacks
  # 피드백 작성
  def create
    content = params[:content]
    device_type = params[:device_type] || 'ios'
    app_version = params[:app_version] || '1.0.0'

    unless content
      render json: { error: 'content는 필수입니다' }, status: :bad_request
      return
    end

    # device_type 유효성 검증
    unless %w[ios android web].include?(device_type)
      render json: { error: 'device_type은 ios, android, web 중 하나여야 합니다' }, status: :bad_request
      return
    end

    feedback = current_user.feedbacks.build(
      content: content,
      device_type: device_type,
      app_version: app_version
    )

    if feedback.save
      render json: {
        id: feedback.id,
        content: feedback.content,
        created_at: format_time(feedback.created_at)
      }, status: :created
    else
      render json: { 
        error: '피드백 작성에 실패했습니다',
        errors: feedback.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /admin/feedbacks
  # 피드백 목록 조회 (관리자용)
  def admin_index
    # TODO: 관리자 인증 로직 추가 필요
    feedbacks = Feedback.includes(:user).order(created_at: :desc)
    
    items = feedbacks.map do |feedback|
      {
        id: feedback.id,
        user: {
          id: feedback.user.id,
          username: feedback.user.username,
          nickname: feedback.user.nickname
        },
        content: feedback.content,
        device_type: feedback.device_type,
        app_version: feedback.app_version,
        created_at: format_time(feedback.created_at)
      }
    end

    render json: {
      items: items,
      total_count: feedbacks.count
    }, status: :ok
  end
end
