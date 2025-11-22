class ApplicationController < ActionController::API
  private

  # 현재 로그인한 유저를 반환하는 메서드
  # 헤더에서 토큰을 가져와서 검증하고, user_id로 유저를 찾습니다
  def current_user
    # Authorization 헤더에서 토큰 가져오기
    # 형식: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    token = request.headers['Authorization']&.split(' ')&.last
    
    return nil unless token

    # 토큰 검증하고 user_id 가져오기
    user_id = JwtService.decode(token)
    return nil unless user_id

    # user_id로 유저 찾기
    @current_user ||= User.find_by(id: user_id)
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
end

