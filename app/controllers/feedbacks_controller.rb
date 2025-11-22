class FeedbacksController < ApplicationController
  # 인증이 필요한 모든 액션
  before_action :authenticate_user!

  # 피드백 저장
  # POST /feedbacks
  def create
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 요청 데이터 받기
    feedback_params = feedback_params_with_user(user)

    # 3. Feedback 생성
    feedback = user.feedbacks.build(feedback_params)

    # 4. 저장 시도
    if feedback.save
      # 성공: 생성된 feedback 정보 반환
      render json: feedback, status: :created
    else
      # 실패: 에러 메시지 반환
      render json: { errors: feedback.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Strong Parameters - 허용된 파라미터만 받기 (보안)
  def feedback_params_with_user(user)
    params.require(:feedback).permit(
      :content,      # 피드백 내용 (필수)
      :app_version,  # 앱 버전 (선택사항)
      :platform      # 플랫폼 (필수, 예: "ios")
    )
  end
end

