class WorkoutsController < ApplicationController
  # 인증이 필요한 모든 액션
  before_action :authenticate_user!

  # 산책 기록 저장
  # POST /workouts
  def create
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 요청 데이터 받기 (iOS에서 보낸 산책 데이터)
    workout_params = workout_params_with_user(user)

    # 3. Workout 생성
    workout = user.workouts.build(workout_params)

    # 4. 저장 시도
    if workout.save
      # 성공: 생성된 workout 정보 반환
      render json: workout, status: :created
    else
      # 실패: 에러 메시지 반환
      render json: { errors: workout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # 산책 기록 조회 (날짜별)
  # GET /workouts?date=2024-11-15
  def index
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 날짜 파라미터 받기 (선택사항)
    date = params[:date]

    # 3. 날짜가 있으면 해당 날짜의 기록만, 없으면 모든 기록
    workouts = if date.present?
                 # 특정 날짜의 기록만 조회
                 user.workouts.where(workout_date: date).order(started_at: :desc)
               else
                 # 모든 기록 조회 (최신순)
                 user.workouts.order(workout_date: :desc, started_at: :desc)
               end

    # 4. JSON 응답 반환
    render json: workouts, status: :ok
  end

  private

  # Strong Parameters - 허용된 파라미터만 받기 (보안)
  def workout_params_with_user(user)
    params.require(:workout).permit(
      :workout_date,      # 날짜 (YYYY-MM-DD)
      :started_at,        # 시작 시간
      :ended_at,          # 종료 시간
      :distance,          # 거리 (미터)
      :steps,             # 걸음수
      :duration,          # 지속 시간 (초)
      :calories           # 칼로리
    )
  end
end

