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
      # 성공: 생성된 workout 정보 반환 (presigned URL 포함)
      render json: workout.as_json.merge(
        image_url: workout.image_url
      ), status: :created
    else
      # 실패: 에러 메시지 반환
      render json: { errors: workout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Presigned URL 발급
  # POST /workouts/presigned_url
  # 클라이언트가 S3에 직접 사진을 업로드할 수 있도록 Presigned URL을 발급합니다
  def presigned_url
    file_name = params[:file_name]
    content_type = params[:content_type] || 'image/jpeg'

    unless file_name
      render json: { error: 'file_name 파라미터가 필요합니다' }, status: :bad_request
      return
    end

    # Presigned URL 생성
    result = S3PresignedUrlService.generate_presigned_url(
      file_name: file_name,
      content_type: content_type
    )

    if result
      render json: {
        presigned_url: result[:url],
        s3_key: result[:key],
        expires_at: result[:expires_at]
      }, status: :ok
    else
      render json: { error: 'Presigned URL 생성에 실패했습니다' }, status: :internal_server_error
    end
  rescue StandardError => e
    render json: { error: '서버 오류가 발생했습니다', message: e.message }, status: :internal_server_error
  end

  # 사진과 함께 산책 기록 저장
  # POST /workouts/with_image
  # 업로드된 사진의 s3_key와 함께 거리, 걸음수, 시간 정보를 저장합니다
  def create_with_image
    user = current_user

    # 요청 데이터 받기
    workout_params = params.require(:workout).permit(
      :workout_date,
      :started_at,
      :ended_at,
      :distance,
      :steps,
      :duration,
      :calories,
      :s3_key  # S3 키만 저장 (presigned URL은 조회 시 생성)
    )

    # Workout 생성
    workout = user.workouts.build(workout_params)

    if workout.save
      # 응답에 presigned GET URL 포함
      render json: workout.as_json.merge(
        image_url: workout.image_url
      ), status: :created
    else
      render json: { errors: workout.errors.full_messages }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: '서버 오류가 발생했습니다', message: e.message }, status: :internal_server_error
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

    # 4. JSON 응답 반환 (각 workout에 presigned URL 포함)
    workouts_with_urls = workouts.map do |workout|
      workout.as_json.merge(
        image_url: workout.image_url
      )
    end
    
    render json: workouts_with_urls, status: :ok
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
      :calories,          # 칼로리
      :s3_key             # S3 키 (선택사항)
    )
  end
end

