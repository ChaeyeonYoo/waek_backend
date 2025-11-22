# 인증 관련 API 컨트롤러
class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:social_verify, :social_signup, :check_id]

  # POST /auth/social/verify
  # 소셜 유저 존재 확인 + 로그인
  def social_verify
    provider = params[:provider]
    provider_id = params[:provider_id]

    # 필수 파라미터 검증
    unless provider && provider_id
      render json: { error: 'provider와 provider_id는 필수입니다' }, status: :bad_request
      return
    end

    # provider 유효성 검증
    unless %w[kakao google apple].include?(provider)
      render json: { error: '지원하지 않는 provider입니다' }, status: :bad_request
      return
    end

    # 유저 찾기
    user = User.active.find_by(provider: provider, provider_id: provider_id)

    if user
      # 기존 유저인 경우 - 로그인 처리
      user.update_last_login!
      token = JwtService.encode(user.id, token_version: user.token_version)

      render json: {
        status: 'EXISTS',
        user: {
          id: user.id,
          username: user.username,
          nickname: user.nickname,
          profile_image_code: user.profile_image_code,
          provider: user.provider
        },
        token: {
          access_token: token,
          token_type: 'Bearer',
          expires_in: nil # 영구 토큰
        }
      }, status: :ok
    else
      # 기존 유저가 아닌 경우 - 회원가입 필요
      render json: {
        status: 'NEED_SIGNUP',
        provider: provider
      }, status: :ok
    end
  end

  # POST /auth/social/signup
  # 최초 회원가입
  def social_signup
    provider = params[:provider]
    provider_id = params[:provider_id]
    username = params[:username]
    nickname = params[:nickname]
    profile_image_code = params[:profile_image_code]

    # 필수 파라미터 검증
    unless provider && provider_id && username && nickname
      render json: { error: 'provider, provider_id, username, nickname은 필수입니다' }, status: :bad_request
      return
    end

    # provider 유효성 검증
    unless %w[kakao google apple].include?(provider)
      render json: { error: '지원하지 않는 provider입니다' }, status: :bad_request
      return
    end

    # username 중복 확인
    if User.exists?(username: username)
      render json: { error: '이미 사용 중인 username입니다' }, status: :conflict
      return
    end

    # provider + provider_id 중복 확인
    if User.exists?(provider: provider, provider_id: provider_id)
      render json: { error: '이미 가입된 소셜 계정입니다' }, status: :conflict
      return
    end

    # profile_image_code 유효성 검증
    if profile_image_code && !(0..4).include?(profile_image_code.to_i)
      render json: { error: 'profile_image_code는 0~4 사이의 값이어야 합니다' }, status: :bad_request
      return
    end

    # 유저 생성
    user = User.new(
      provider: provider,
      provider_id: provider_id,
      username: username,
      nickname: nickname,
      profile_image_code: profile_image_code&.to_i,
      token_version: 1,
      is_subscribed: false,
      is_trial: false,
      has_used_trial: false
    )

    if user.save
      user.update_last_login!
      token = JwtService.encode(user.id, token_version: user.token_version)

      render json: {
        user: {
          id: user.id,
          username: user.username,
          nickname: user.nickname,
          profile_image_code: user.profile_image_code,
          provider: user.provider,
          created_at: format_time(user.created_at),
          updated_at: format_time(user.updated_at)
        },
        token: {
          access_token: token,
          token_type: 'Bearer',
          expires_in: nil # 영구 토큰
        }
      }, status: :created
    else
      render json: { 
        error: '회원가입에 실패했습니다',
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /users/check_id
  # username 중복 확인
  def check_id
    username = params[:username]

    unless username
      render json: { error: 'username은 필수입니다' }, status: :bad_request
      return
    end

    available = !User.exists?(username: username)

    render json: {
      username: username,
      available: available
    }, status: :ok
  end

  # GET /me
  # 내 정보 조회
  def me
    render json: {
      id: current_user.id,
      username: current_user.username,
      nickname: current_user.nickname,
      profile_image_code: current_user.profile_image_code,
      provider: current_user.provider,
      created_at: format_time(current_user.created_at),
      updated_at: format_time(current_user.updated_at)
    }, status: :ok
  end

  # POST /auth/logout
  # 로그아웃 (token_version +1)
  def logout
    current_user.increment_token_version!
    head :no_content
  end

  # DELETE /me
  # 계정 삭제 (soft delete)
  def delete_me
    current_user.soft_delete!
    head :no_content
  end
end
