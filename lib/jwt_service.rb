# JWT 토큰을 발급하고 검증하는 서비스 클래스
# token_version을 포함하여 토큰 무효화를 지원합니다
class JwtService
  # JWT Secret Key - 토큰을 서명할 때 사용하는 비밀키
  # .env 파일에서 가져오거나, 기본값 사용
  SECRET_KEY = ENV['JWT_SECRET'] || 'your-secret-key-change-this-in-production'

  # 토큰 발급 메서드 (token_version 포함)
  # @param user_id [Integer] 사용자 ID
  # @param token_version [Integer] 토큰 버전 (기본값: 1)
  # @return [String] JWT 토큰
  def self.encode(user_id, token_version: 1)
    payload = {
      user_id: user_id,
      token_version: token_version,
      iat: Time.current.to_i # 발급 시간
    }
    
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  # 토큰 검증 메서드
  # @param token [String] 검증할 JWT 토큰
  # @return [Hash, nil] { user_id: Integer, token_version: Integer } 또는 nil
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { 
      algorithm: 'HS256',
      verify_expiration: false  # 만료 시간 검증 안 함
    })
    
    payload = decoded[0]
    {
      user_id: payload['user_id'],
      token_version: payload['token_version'] || 1
    }
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT 디코드 실패: #{e.message}"
    nil
  end

  # 토큰에서 user_id만 추출 (간단한 경우)
  # @param token [String] JWT 토큰
  # @return [Integer, nil] user_id 또는 nil
  def self.user_id_from_token(token)
    decoded = decode(token)
    decoded&.dig(:user_id)
  end
end
