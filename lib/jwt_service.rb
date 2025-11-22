# JWT 토큰을 발급하고 검증하는 서비스 클래스
# 이 클래스는 토큰을 만들고, 토큰을 확인하는 역할을 합니다
class JwtService
  # JWT Secret Key - 토큰을 서명할 때 사용하는 비밀키
  # .env 파일에서 가져오거나, 기본값 사용
  SECRET_KEY = ENV['JWT_SECRET'] || 'your-secret-key-change-this-in-production'

  # 토큰 발급 메서드
  # user_id를 받아서 JWT 토큰을 만들어서 반환합니다
  def self.encode(user_id)
    # 토큰이 만료되는 시간 설정 (30일 후)
    exp = 30.days.from_now.to_i
    
    # JWT 토큰 생성
    # payload: 토큰에 담을 정보 (user_id, 만료시간)
    payload = {
      user_id: user_id,
      exp: exp  # expiration (만료 시간)
    }
    
    # JWT.encode: 토큰 생성
    # - payload: 토큰에 담을 정보
    # - SECRET_KEY: 서명에 사용할 비밀키
    # - 'HS256': 암호화 알고리즘
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  # 토큰 검증 메서드
  # token을 받아서 유효한지 확인하고, user_id를 반환합니다
  def self.decode(token)
    # JWT.decode: 토큰을 해독
    # - token: 검증할 토큰
    # - SECRET_KEY: 서명 확인에 사용할 비밀키
    # - true: 알고리즘 검증 활성화
    # - algorithm: 'HS256' 알고리즘 사용
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
    
    # decoded는 배열 형태: [payload, header]
    # payload에서 user_id를 가져옴
    decoded[0]['user_id']
  rescue JWT::DecodeError, JWT::ExpiredSignature
    # 토큰이 잘못되었거나 만료된 경우
    nil
  end
end

