class ApplicationController < ActionController::API
  # ISO8601 UTC 형식으로 시간 변환
  before_action :set_time_zone
  # 인증이 필요한 모든 액션에 적용 (개별 컨트롤러에서 skip 가능)
  before_action :authenticate_user!

  private

  # 현재 로그인한 유저를 반환하는 메서드
  # 헤더에서 토큰을 가져와서 검증하고, user_id로 유저를 찾습니다
  # token_version도 검증합니다
  def current_user
    # Authorization 헤더에서 토큰 가져오기
    # 형식: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    token = request.headers['Authorization']&.split(' ')&.last
    
    return nil unless token

    # 토큰 검증하고 user_id, token_version 가져오기
    decoded = JwtService.decode(token)
    return nil unless decoded

    user_id = decoded[:user_id]
    token_version = decoded[:token_version] || 1

    # user_id로 유저 찾기
    user = User.find_by(id: user_id)
    return nil unless user

    # Soft delete 체크
    return nil if user.deleted_at.present?

    # token_version 검증
    return nil if user.token_version != token_version

    @current_user ||= user
  end

  # 인증이 필요한 액션에서 사용
  # 토큰이 없거나 유효하지 않으면 에러 반환
  def authenticate_user!
    unless current_user
      render json: { error: '인증이 필요합니다' }, status: :unauthorized
      return false
    end
    true
  end

  # 시간대 설정
  # 현재는 한국 시간대(KST) 사용, 추후 UTC로 전환 가능
  def set_time_zone
    Time.zone = 'Asia/Seoul'  # 한국 시간대 (UTC+09:00)
    # 추후 글로벌 서비스 시: Time.zone = 'UTC'로 변경
  end

  # ISO8601 오프셋 형식으로 시간 포맷팅
  # 
  # 현재: "2025-11-25T18:36:07+09:00" (KST)
  # 추후 UTC 전환 시: "2025-11-25T09:36:07Z" (UTC)
  # 
  # @param datetime [ActiveSupport::TimeWithZone, Time, DateTime] 시간 객체
  # @return [String, nil] ISO8601 형식 문자열 또는 nil
  def format_time(datetime)
    return nil unless datetime
    datetime.in_time_zone(Time.zone).iso8601
  end
end
