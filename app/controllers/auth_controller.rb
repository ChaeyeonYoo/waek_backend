class AuthController < ApplicationController
  # 소셜 로그인 API
  # POST /auth/social_login
  def social_login
    # 1. 요청 데이터 받기 (iOS에서 보낸 데이터)
    provider = params[:provider]                    # 1: apple, 2: kakao, 3: google
    provider_user_id = params[:provider_user_id]    # 소셜 로그인 제공자에서 받은 유저 ID
    social_email = params[:social_email]             # 소셜 로그인 이메일
    nickname = params[:nickname]                     # 닉네임
    profile_image_key = params[:profile_image_key]  # 프로필 사진 키 (선택사항)

    # 2. 필수 파라미터 검증
    unless provider && provider_user_id && nickname
      render json: { error: '필수 파라미터가 없습니다 (provider, provider_user_id, nickname)' }, 
             status: :bad_request
      return
    end

    # 3. 유저 찾기 또는 생성
    # find_or_create_by: 있으면 찾고, 없으면 생성
    user = User.find_or_create_by(
      provider: provider,
      provider_user_id: provider_user_id
    ) do |u|
      # 새로 생성할 때만 실행되는 블록
      u.nickname = nickname
      u.social_email = social_email if social_email.present?
      u.profile_image_key = profile_image_key if profile_image_key.present?
    end

    # 4. 유저 정보 업데이트 (이미 존재하는 경우에도 최신 정보로 업데이트)
    update_params = { nickname: nickname }
    update_params[:social_email] = social_email if social_email.present?
    update_params[:profile_image_key] = profile_image_key if profile_image_key.present?
    user.update(update_params)

    # 5. 유효성 검사 실패 시 에러 반환
    unless user.valid?
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      return
    end

    # 6. JWT 토큰 발급
    token = JwtService.encode(user.id)

    # 7. 응답 반환 (토큰 + 유저 정보)
    render json: {
      token: token,
      user: {
        id: user.id,
        nickname: user.nickname,
        profile_image_key: user.profile_image_key,
        provider: user.provider,
        is_premium: user.is_premium
      }
    }, status: :ok
  rescue StandardError => e
    # 예외 발생 시 에러 응답
    render json: { error: '서버 오류가 발생했습니다', message: e.message }, status: :internal_server_error
  end
end

