class DailyWorkoutsController < ApplicationController
  # 인증이 필요한 모든 액션
  before_action :authenticate_user!

  # 일일 요약 조회
  # GET /daily_workouts/:date
  # 예: GET /daily_workouts/2024-11-15
  def show
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 날짜 파라미터 받기
    date = params[:date]

    # 3. 날짜 검증
    unless date.present?
      render json: { error: '날짜가 필요합니다' }, status: :bad_request
      return
    end

    # 4. 해당 날짜의 DailyWorkout 찾기
    daily_workout = user.daily_workouts.find_by(date: date)

    # 5. 있으면 반환, 없으면 기본값으로 생성해서 반환
    if daily_workout
      render json: daily_workout, status: :ok
    else
      # 없으면 기본값으로 새로 생성 (조회용)
      daily_workout = user.daily_workouts.build(
        date: date,
        is_workout_goal_achieved: false,
        has_walk_10min: false
      )
      
      # 저장하지 않고 그냥 반환 (또는 저장할 수도 있음)
      render json: daily_workout, status: :ok
    end
  end

  # 일일 요약 목록 조회 (선택사항)
  # GET /daily_workouts
  def index
    # 1. 현재 로그인한 유저 가져오기
    user = current_user

    # 2. 시작 날짜와 종료 날짜 파라미터 (선택사항)
    start_date = params[:start_date]
    end_date = params[:end_date]

    # 3. 조건부 조회
    daily_workouts = user.daily_workouts
    
    if start_date.present? && end_date.present?
      # 날짜 범위로 조회
      daily_workouts = daily_workouts.where(date: start_date..end_date)
    end

    # 4. 날짜순 정렬 (최신순)
    daily_workouts = daily_workouts.order(date: :desc)

    # 5. JSON 응답 반환
    render json: daily_workouts, status: :ok
  end
end

