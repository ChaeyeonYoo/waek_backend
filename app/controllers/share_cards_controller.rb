class ShareCardsController < ApplicationController
  # 인증이 필요한 모든 액션
  before_action :authenticate_user!

  # 카드 저장
  # POST /share_cards
  def create
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 요청 데이터 받기
    share_card_params = share_card_params_with_user(user)

    # 3. ShareCard 생성
    share_card = user.share_cards.build(share_card_params)

    # 4. 저장 시도
    if share_card.save
      # 성공: 생성된 share_card 정보 반환
      render json: share_card, status: :created
    else
      # 실패: 에러 메시지 반환
      render json: { errors: share_card.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # 카드 조회 (날짜별)
  # GET /share_cards?date=2024-11-15
  def index
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 날짜 파라미터 받기 (선택사항)
    date = params[:date]

    # 3. 날짜가 있으면 해당 날짜의 카드만, 없으면 모든 카드
    share_cards = if date.present?
                    # 특정 날짜의 카드만 조회
                    user.share_cards.where(card_date: date).order(created_at: :desc)
                  else
                    # 모든 카드 조회 (최신순)
                    user.share_cards.order(card_date: :desc, created_at: :desc)
                  end

    # 4. JSON 응답 반환
    render json: share_cards, status: :ok
  end

  private

  # Strong Parameters - 허용된 파라미터만 받기 (보안)
  def share_card_params_with_user(user)
    params.require(:share_card).permit(
      :workout_id,         # 연결된 Workout ID
      :card_date,          # 카드에 표시되는 날짜
      :frame_theme_key,    # 프레임/테마 키
      :image_url,          # 완성된 카드 이미지 URL
      :distance,           # Workout에서 복사한 스냅샷 값 (미터)
      :steps,              # Workout에서 복사한 스냅샷 값
      :duration            # Workout에서 복사한 스냅샷 값 (초)
    )
  end
end

