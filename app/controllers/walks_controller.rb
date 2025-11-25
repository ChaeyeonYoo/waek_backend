# Walk (산책 기록) 관련 API 컨트롤러
class WalksController < ApplicationController
  require 'securerandom'
  before_action :authenticate_user!

  # POST /uploads/presigned_url
  # 산책 사진 업로드용 presigned URL 발급
  def presigned_url
    content_type = params[:content_type] || 'image/jpeg'
    use_case = params[:use_case] || 'walk_card'

    # content_type에서 확장자 추출
    extension = case content_type
                when 'image/jpeg', 'image/jpg'
                  'jpg'
                when 'image/png'
                  'png'
                when 'image/gif'
                  'gif'
                when 'image/webp'
                  'webp'
                else
                  'jpg' # 기본값
                end

    # 자동으로 파일명 생성
    file_name = "walk_#{Time.current.to_i}_#{SecureRandom.hex(8)}.#{extension}"

    result = S3PresignedUrlService.generate_presigned_url(
      file_name: file_name,
      content_type: content_type
    )

    if result
      render json: {
        upload_url: result[:url],
        photo_key: result[:key],
        expires_in: 600 # 10분
      }, status: :ok
    else
      render json: { error: 'Presigned URL 생성에 실패했습니다' }, status: :internal_server_error
    end
  end

  # POST /walks
  # 산책 기록 생성
  def create
    walk_params = params.require(:walk).permit(
      :distance_meters,
      :step_count,
      :duration_seconds,
      :started_at,
      :ended_at,
      :photo_key
    )

    # 필수 필드 검증
    unless walk_params[:started_at] && walk_params[:ended_at] && walk_params[:duration_seconds]
      render json: { error: 'started_at, ended_at, duration_seconds는 필수입니다' }, status: :bad_request
      return
    end

    # 시간 파싱 (현재 시간대 기준)
    # ISO8601 형식을 파싱하여 현재 Time.zone(Asia/Seoul)으로 변환
    # 클라이언트가 오프셋을 포함한 ISO8601을 보내면 자동으로 변환됩니다
    begin
      walk_params[:started_at] = Time.zone.parse(walk_params[:started_at])
      walk_params[:ended_at] = Time.zone.parse(walk_params[:ended_at])
    rescue ArgumentError
      render json: { error: '시간 형식이 올바르지 않습니다 (ISO8601 형식 필요)' }, status: :bad_request
      return
    end

    walk = current_user.walks.build(walk_params)
    walk.status = 'active'

    if walk.save
      render json: walk_response(walk), status: :created
    else
      render json: { 
        error: '산책 기록 생성에 실패했습니다',
        errors: walk.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /walks
  # 산책 기록 목록 조회
  def index
    walks = current_user.walks.active.order(started_at: :desc)
    
    # 페이지네이션 (선택적)
    page = params[:page]&.to_i || 1
    page = 1 if page < 1  # 최소값: 1
    
    per_page = params[:per_page]&.to_i || 20
    per_page = [[per_page, 100].min, 1].max  # 최소값: 1, 최댓값: 100
    
    total_count = walks.count
    walks = walks.limit(per_page).offset((page - 1) * per_page)

    items = walks.map { |walk| walk_list_response(walk) }

    render json: {
      items: items,
      page: page,
      per_page: per_page,
      total_count: total_count
    }, status: :ok
  end

  # GET /walks/:id
  # 산책 기록 상세 조회
  def show
    walk = current_user.walks.active.find_by(id: params[:id])

    unless walk
      render json: { error: '산책 기록을 찾을 수 없습니다' }, status: :not_found
      return
    end

    render json: walk_response(walk), status: :ok
  end

  # DELETE /walks/:id
  # 산책 기록 삭제 (soft delete)
  def destroy
    walk = current_user.walks.active.find_by(id: params[:id])

    unless walk
      render json: { error: '산책 기록을 찾을 수 없습니다' }, status: :not_found
      return
    end

    walk.soft_delete!
    head :no_content
  end

  private

  # Walk 상세 응답 포맷
  def walk_response(walk)
    {
      id: walk.id,
      distance_meters: walk.distance_meters,
      step_count: walk.step_count,
      duration_seconds: walk.duration_seconds,
      started_at: format_time(walk.started_at),
      ended_at: format_time(walk.ended_at),
      photo: {
        key: walk.photo_key,
        url: walk.photo_url
      },
      created_at: format_time(walk.created_at),
      updated_at: format_time(walk.updated_at)
    }
  end

  # Walk 목록 응답 포맷
  def walk_list_response(walk)
    {
      id: walk.id,
      date: walk.date&.to_s,
      distance_meters: walk.distance_meters,
      step_count: walk.step_count,
      duration_seconds: walk.duration_seconds,
      photo: {
        key: walk.photo_key,
        url: walk.photo_url
      },
      created_at: format_time(walk.created_at),
      updated_at: format_time(walk.updated_at)
    }
  end
end

