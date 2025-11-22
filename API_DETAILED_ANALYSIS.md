# 왹왹이(waek) API 상세 분석 문서

각 API 엔드포인트를 하나하나 뜯어서 분석한 문서입니다.

---

## 📋 목차

1. [인증 시스템](#인증-시스템)
2. [인증 API](#인증-api)
3. [산책 기록 API](#산책-기록-api)
4. [일일 요약 API](#일일-요약-api)
5. [카드 API](#카드-api)
6. [피드백 API](#피드백-api)

---

## 인증 시스템

### ApplicationController

모든 컨트롤러의 기본 클래스입니다. 인증 로직을 제공합니다.

#### `current_user` 메서드
```ruby
def current_user
  token = request.headers['Authorization']&.split(' ')&.last
  return nil unless token
  
  user_id = JwtService.decode(token)
  return nil unless user_id
  
  @current_user ||= User.find_by(id: user_id)
end
```

**동작 방식:**
1. `Authorization` 헤더에서 토큰 추출 (`Bearer <token>` 형식)
2. `JwtService.decode(token)`으로 토큰 검증 및 `user_id` 추출
3. `user_id`로 User 찾기
4. 메모이제이션 (`@current_user`)으로 중복 조회 방지

#### `authenticate_user!` 메서드
```ruby
def authenticate_user!
  unless current_user
    render json: { error: '인증이 필요합니다' }, status: :unauthorized
    return false
  end
  true
end
```

**사용:**
- `before_action :authenticate_user!`로 컨트롤러에 적용
- 인증 실패 시 401 Unauthorized 반환

---

## 인증 API

### 1. GET /auth/verify_token - 토큰 검증

**인증 필요**: ❌ 없음 (토큰 자체를 검증하는 API)

#### 요청
```
GET /auth/verify_token
Headers:
  Authorization: Bearer <JWT_TOKEN>
```

#### 처리 로직
```ruby
def verify_token
  # 1. Authorization 헤더에서 토큰 추출
  token = request.headers['Authorization']&.split(' ')&.last
  
  # 2. 토큰 없으면 에러
  unless token
    render json: { error: '토큰이 필요합니다' }, status: :bad_request
    return
  end

  # 3. JwtService.decode로 토큰 검증
  user_id = JwtService.decode(token)
  
  # 4. 토큰이 유효하지 않으면 에러
  unless user_id
    render json: { error: '유효하지 않은 토큰입니다' }, status: :unauthorized
    return
  end

  # 5. 유저 찾기
  user = User.find_by(id: user_id)
  
  # 6. 유저 없으면 에러
  unless user
    render json: { error: '유저를 찾을 수 없습니다' }, status: :not_found
    return
  end

  # 7. 성공 응답
  render json: {
    valid: true,
    user: { ... }
  }
end
```

#### 응답 (200 OK)
```json
{
  "valid": true,
  "user": {
    "id": 1,
    "login_id": "user123",
    "nickname": "홍길동",
    "profile_image_key": 2,
    "provider": 1,
    "is_premium": false
  }
}
```

#### 에러 응답
- **400 Bad Request**: 토큰이 없음
- **401 Unauthorized**: 토큰이 유효하지 않음
- **404 Not Found**: 유저를 찾을 수 없음

#### 사용 시나리오
- 앱 시작 시 저장된 토큰 검증
- 토큰 만료 여부 확인 (현재는 영구 토큰이므로 만료 없음)

---

### 2. POST /auth/create_token - 기존 유저 토큰 생성

**인증 필요**: ❌ 없음

#### 요청
```
POST /auth/create_token
Content-Type: application/json

{
  "provider": 1,
  "provider_id": "apple_user_12345"
}
```

#### 처리 로직
```ruby
def create_token
  # 1. 파라미터 추출
  provider = params[:provider]
  provider_id = params[:provider_id]

  # 2. 필수 파라미터 검증
  unless provider && provider_id
    render json: { error: '필수 파라미터가 없습니다' }, status: :bad_request
    return
  end

  # 3. 유저 찾기 (provider + provider_id 조합)
  user = User.find_by(provider: provider, provider_id: provider_id)

  # 4. 유저 없으면 404
  unless user
    render json: { error: '유저를 찾을 수 없습니다' }, status: :not_found
    return
  end

  # 5. 영구 토큰 발급
  token = JwtService.encode_permanent(user.id)

  # 6. 토큰 + 유저 정보 반환
  render json: {
    token: token,
    user: { ... }
  }
end
```

#### 응답 (200 OK)
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "login_id": "user123",
    "nickname": "홍길동",
    "profile_image_key": 2,
    "provider": 1,
    "is_premium": false
  }
}
```

#### 에러 응답
- **400 Bad Request**: 필수 파라미터 누락
- **404 Not Found**: 유저를 찾을 수 없음 (신규 유저)

#### 사용 시나리오
- 소셜 로그인 후 기존 유저인 경우
- iOS 앱에서 Apple/Kakao/Google 로그인 성공 후 호출

---

### 3. POST /auth/register - 신규 유저 등록

**인증 필요**: ❌ 없음

#### 요청
```
POST /auth/register
Content-Type: application/json

{
  "login_id": "unique_user123",
  "nickname": "홍길동",
  "profile_image_key": 2,
  "provider": 1,
  "provider_id": "apple_user_12345"
}
```

#### 처리 로직
```ruby
def register
  # 1. 파라미터 추출
  login_id = params[:login_id]
  nickname = params[:nickname]
  profile_image_key = params[:profile_image_key]
  provider = params[:provider]
  provider_id = params[:provider_id]

  # 2. 필수 파라미터 검증
  unless login_id && nickname && profile_image_key && provider && provider_id
    render json: { error: '필수 파라미터가 없습니다' }, status: :bad_request
    return
  end

  # 3. login_id 중복 확인
  if User.exists?(login_id: login_id)
    render json: { error: '이미 사용 중인 아이디입니다' }, status: :conflict
    return
  end

  # 4. provider + provider_id 조합 중복 확인
  if User.exists?(provider: provider, provider_id: provider_id)
    render json: { error: '이미 등록된 유저입니다' }, status: :conflict
    return
  end

  # 5. profile_image_key 범위 확인 (0-4)
  unless (0..4).include?(profile_image_key.to_i)
    render json: { error: '프로필 이미지 키는 0부터 4까지의 값이어야 합니다' }, 
           status: :bad_request
    return
  end

  # 6. 신규 유저 생성
  user = User.new(
    login_id: login_id,
    nickname: nickname,
    profile_image_key: profile_image_key.to_i,
    provider: provider,
    provider_id: provider_id
  )

  # 7. 저장 시도
  if user.save
    # 영구 토큰 발급
    token = JwtService.encode_permanent(user.id)
    render json: { token: token, user: { ... } }, status: :created
  else
    # 유효성 검사 실패
    render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
  end
end
```

#### 응답 (201 Created)
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "login_id": "unique_user123",
    "nickname": "홍길동",
    "profile_image_key": 2,
    "provider": 1,
    "is_premium": false
  }
}
```

#### 에러 응답
- **400 Bad Request**: 필수 파라미터 누락 또는 profile_image_key 범위 초과
- **409 Conflict**: login_id 중복 또는 이미 등록된 유저
- **422 Unprocessable Entity**: 유효성 검사 실패

#### 사용 시나리오
- 소셜 로그인 후 신규 유저인 경우
- 회원가입 화면에서 정보 입력 후 호출

---

### 4. GET /auth/check_login_id - login_id 중복 확인

**인증 필요**: ❌ 없음

#### 요청
```
GET /auth/check_login_id?login_id=test123
```

#### 처리 로직
```ruby
def check_login_id
  login_id = params[:login_id]

  unless login_id
    render json: { error: 'login_id 파라미터가 필요합니다' }, status: :bad_request
    return
  end

  available = !User.exists?(login_id: login_id)

  render json: {
    login_id: login_id,
    available: available,
    message: available ? '사용 가능한 아이디입니다' : '이미 사용 중인 아이디입니다'
  }
end
```

#### 응답 (200 OK)
```json
{
  "login_id": "test123",
  "available": true,
  "message": "사용 가능한 아이디입니다"
}
```

#### 사용 시나리오
- 회원가입 화면에서 실시간 중복 확인
- 사용자가 아이디 입력 중에 확인

---

## 산책 기록 API

### 1. POST /workouts - 산책 기록 저장

**인증 필요**: ✅ (JWT Bearer Token)

#### 요청
```
POST /workouts
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "workout": {
    "workout_date": "2024-11-22",
    "started_at": "2024-11-22T10:00:00Z",
    "ended_at": "2024-11-22T10:30:00Z",
    "distance": 2500.5,
    "steps": 3500,
    "duration": 1800,
    "calories": 120.5,
    "s3_key": "workouts/1234567890_abc123_photo.jpg"  // 선택사항
  }
}
```

#### 처리 로직
```ruby
def create
  # 1. current_user로 현재 로그인한 유저 가져오기
  user = current_user

  # 2. Strong Parameters로 허용된 파라미터만 추출
  workout_params = workout_params_with_user(user)

  # 3. user.workouts.build로 Workout 생성 (user_id 자동 설정)
  workout = user.workouts.build(workout_params)

  # 4. 저장 시도
  if workout.save
    # 성공: workout.as_json으로 JSON 변환 후 image_url 추가
    render json: workout.as_json.merge(
      image_url: workout.image_url  # presigned GET URL 생성
    ), status: :created
  else
    # 실패: 유효성 검사 에러 반환
    render json: { errors: workout.errors.full_messages }, status: :unprocessable_entity
  end
end
```

#### 응답 (201 Created)
```json
{
  "id": 1,
  "user_id": 1,
  "workout_date": "2024-11-22",
  "started_at": "2024-11-22T10:00:00.000Z",
  "ended_at": "2024-11-22T10:30:00.000Z",
  "distance": "2500.5",
  "steps": 3500,
  "duration": 1800,
  "calories": "120.5",
  "s3_key": "workouts/1234567890_abc123_photo.jpg",
  "image_url": "https://bucket.s3.region.amazonaws.com/...?X-Amz-Signature=...",
  "created_at": "2024-11-22T10:30:00.000Z",
  "updated_at": "2024-11-22T10:30:00.000Z"
}
```

#### 에러 응답
- **401 Unauthorized**: 인증 실패
- **422 Unprocessable Entity**: 유효성 검사 실패

#### 유효성 검사
- `workout_date`: 필수
- `started_at`: 필수
- `ended_at`: 필수
- `duration`: 필수, 0보다 커야 함
- `ended_at > started_at`: 커스텀 validation

---

### 2. POST /workouts/presigned_url - Presigned URL 발급

**인증 필요**: ✅

#### 요청
```
POST /workouts/presigned_url
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "file_name": "workout_photo.jpg",
  "content_type": "image/jpeg"
}
```

#### 처리 로직
```ruby
def presigned_url
  # 1. 파라미터 추출
  file_name = params[:file_name]
  content_type = params[:content_type] || 'image/jpeg'

  # 2. file_name 필수 검증
  unless file_name
    render json: { error: 'file_name 파라미터가 필요합니다' }, status: :bad_request
    return
  end

  # 3. S3PresignedUrlService로 Presigned URL 생성
  result = S3PresignedUrlService.generate_presigned_url(
    file_name: file_name,
    content_type: content_type
  )

  # 4. 결과 반환
  if result
    render json: {
      presigned_url: result[:url],      # PUT 요청용 URL
      s3_key: result[:key],              # 저장할 S3 키
      expires_at: result[:expires_at]    # 만료 시간
    }
  else
    render json: { error: 'Presigned URL 생성에 실패했습니다' }, 
           status: :internal_server_error
  end
end
```

#### S3PresignedUrlService.generate_presigned_url 내부 동작
```ruby
def self.generate_presigned_url(file_name:, content_type:, expires_in: 3600)
  bucket = ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
  
  # S3 키 생성: "workouts/{timestamp}_{random}_{filename}"
  timestamp = Time.current.to_i
  s3_key = "workouts/#{timestamp}_#{SecureRandom.hex(8)}_#{file_name}"

  # Presigned PUT URL 생성 (private 객체로 업로드)
  signer = Aws::S3::Presigner.new(client: s3_client)
  url = signer.presigned_url(
    :put_object,
    bucket: bucket,
    key: s3_key,
    content_type: content_type,
    expires_in: expires_in
    # acl 없음 → private로 업로드됨
  )

  {
    url: url,
    key: s3_key,
    expires_at: Time.current + expires_in.seconds,
    bucket: bucket
  }
end
```

#### 응답 (200 OK)
```json
{
  "presigned_url": "https://bucket.s3.region.amazonaws.com/workouts/...?X-Amz-Algorithm=...&X-Amz-Signature=...",
  "s3_key": "workouts/1732262400_a1b2c3d4_workout_photo.jpg",
  "expires_at": "2024-11-22T15:30:00Z"
}
```

#### 사용 시나리오
1. iOS 앱에서 사진 업로드 전에 호출
2. 받은 `presigned_url`로 S3에 직접 PUT 요청
3. 받은 `s3_key`를 저장해두었다가 `/workouts/with_image` 호출 시 사용

---

### 3. POST /workouts/with_image - 사진과 함께 기록 저장

**인증 필요**: ✅

#### 요청
```
POST /workouts/with_image
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "workout": {
    "workout_date": "2024-11-22",
    "started_at": "2024-11-22T10:00:00Z",
    "ended_at": "2024-11-22T10:30:00Z",
    "distance": 2500.5,
    "steps": 3500,
    "duration": 1800,
    "calories": 120.5,
    "s3_key": "workouts/1732262400_a1b2c3d4_workout_photo.jpg"
  }
}
```

#### 처리 로직
```ruby
def create_with_image
  user = current_user

  # 1. Strong Parameters로 허용된 파라미터만 추출
  workout_params = params.require(:workout).permit(
    :workout_date,
    :started_at,
    :ended_at,
    :distance,
    :steps,
    :duration,
    :calories,
    :s3_key  # S3 키만 저장
  )

  # 2. Workout 생성
  workout = user.workouts.build(workout_params)

  # 3. 저장 시도
  if workout.save
    # 성공: presigned GET URL 포함하여 반환
    render json: workout.as_json.merge(
      image_url: workout.image_url  # s3_key 기반으로 presigned GET URL 생성
    ), status: :created
  else
    render json: { errors: workout.errors.full_messages }, status: :unprocessable_entity
  end
end
```

#### Workout#image_url 메서드
```ruby
def image_url(expires_in: 3600)
  return nil if s3_key.blank?
  S3PresignedUrlService.presigned_get_url(s3_key, expires_in: expires_in)
end
```

#### 응답 (201 Created)
```json
{
  "id": 1,
  "user_id": 1,
  "workout_date": "2024-11-22",
  "started_at": "2024-11-22T10:00:00.000Z",
  "ended_at": "2024-11-22T10:30:00.000Z",
  "distance": "2500.5",
  "steps": 3500,
  "duration": 1800,
  "calories": "120.5",
  "s3_key": "workouts/1732262400_a1b2c3d4_workout_photo.jpg",
  "image_url": "https://bucket.s3.region.amazonaws.com/workouts/...?X-Amz-Signature=...",
  "created_at": "2024-11-22T10:35:00.000Z",
  "updated_at": "2024-11-22T10:35:00.000Z"
}
```

#### 사용 시나리오
1. `/workouts/presigned_url`로 Presigned URL 받기
2. Presigned URL로 S3에 사진 업로드 (PUT 요청)
3. 업로드 완료 후 이 API로 기록 저장 (`s3_key` 포함)

---

### 4. GET /workouts - 산책 기록 조회

**인증 필요**: ✅

#### 요청
```
GET /workouts
Authorization: Bearer <JWT_TOKEN>

# 또는 특정 날짜만 조회
GET /workouts?date=2024-11-22
Authorization: Bearer <JWT_TOKEN>
```

#### 처리 로직
```ruby
def index
  user = current_user
  date = params[:date]

  # 1. 날짜 파라미터에 따라 필터링
  workouts = if date.present?
    # 특정 날짜의 기록만 조회
    user.workouts.where(workout_date: date).order(started_at: :desc)
  else
    # 모든 기록 조회 (최신순)
    user.workouts.order(workout_date: :desc, started_at: :desc)
  end

  # 2. 각 workout에 presigned GET URL 추가
  workouts_with_urls = workouts.map do |workout|
    workout.as_json.merge(
      image_url: workout.image_url  # s3_key가 있으면 presigned URL 생성
    )
  end
  
  render json: workouts_with_urls, status: :ok
end
```

#### 응답 (200 OK)
```json
[
  {
    "id": 1,
    "user_id": 1,
    "workout_date": "2024-11-22",
    "started_at": "2024-11-22T10:00:00.000Z",
    "ended_at": "2024-11-22T10:30:00.000Z",
    "distance": "2500.5",
    "steps": 3500,
    "duration": 1800,
    "calories": "120.5",
    "s3_key": "workouts/1732262400_a1b2c3d4_workout_photo.jpg",
    "image_url": "https://bucket.s3.region.amazonaws.com/...?X-Amz-Signature=...",
    "created_at": "2024-11-22T10:30:00.000Z",
    "updated_at": "2024-11-22T10:30:00.000Z"
  },
  {
    "id": 2,
    "workout_date": "2024-11-21",
    "s3_key": null,
    "image_url": null,  // s3_key가 없으면 null
    ...
  }
]
```

#### 특징
- `s3_key`가 있으면 `image_url`에 presigned GET URL 포함
- `s3_key`가 없으면 `image_url`은 `null`
- 각 요청마다 새로운 presigned URL 생성 (1시간 유효)

---

## 일일 요약 API

### 1. GET /daily_workouts/:date - 특정 날짜의 일일 요약

**인증 필요**: ✅

#### 요청
```
GET /daily_workouts/2024-11-22
Authorization: Bearer <JWT_TOKEN>
```

#### 처리 로직
```ruby
def show
  user = current_user
  date = params[:date]

  # 1. 날짜 검증
  unless date.present?
    render json: { error: '날짜가 필요합니다' }, status: :bad_request
    return
  end

  # 2. 해당 날짜의 DailyWorkout 찾기
  daily_workout = user.daily_workouts.find_by(date: date)

  # 3. 있으면 반환, 없으면 기본값으로 생성해서 반환 (저장하지 않음)
  if daily_workout
    render json: daily_workout, status: :ok
  else
    # 없으면 기본값으로 새로 생성 (조회용, 저장하지 않음)
    daily_workout = user.daily_workouts.build(
      date: date,
      is_workout_goal_achieved: false,
      has_walk_10min: false
    )
    render json: daily_workout, status: :ok
  end
end
```

#### 응답 (200 OK)
```json
{
  "id": 1,
  "user_id": 1,
  "date": "2024-11-22",
  "is_workout_goal_achieved": true,
  "has_walk_10min": true,
  "created_at": "2024-11-22T00:00:00.000Z",
  "updated_at": "2024-11-22T23:59:59.000Z"
}
```

**또는 데이터가 없으면:**
```json
{
  "id": null,
  "user_id": 1,
  "date": "2024-11-22",
  "is_workout_goal_achieved": false,
  "has_walk_10min": false,
  "created_at": null,
  "updated_at": null
}
```

#### 특징
- 데이터가 없어도 기본값으로 응답 반환
- 실제로 저장하지는 않음 (메모리상 객체만 생성)

---

### 2. GET /daily_workouts - 일일 요약 목록 조회

**인증 필요**: ✅

#### 요청
```
GET /daily_workouts
Authorization: Bearer <JWT_TOKEN>

# 또는 날짜 범위로 조회
GET /daily_workouts?start_date=2024-11-01&end_date=2024-11-30
Authorization: Bearer <JWT_TOKEN>
```

#### 처리 로직
```ruby
def index
  user = current_user
  start_date = params[:start_date]
  end_date = params[:end_date]

  # 1. 기본적으로 모든 daily_workouts 조회
  daily_workouts = user.daily_workouts
  
  # 2. 날짜 범위가 있으면 필터링
  if start_date.present? && end_date.present?
    daily_workouts = daily_workouts.where(date: start_date..end_date)
  end

  # 3. 날짜순 정렬 (최신순)
  daily_workouts = daily_workouts.order(date: :desc)

  render json: daily_workouts, status: :ok
end
```

#### 응답 (200 OK)
```json
[
  {
    "id": 1,
    "user_id": 1,
    "date": "2024-11-22",
    "is_workout_goal_achieved": true,
    "has_walk_10min": true
  },
  {
    "id": 2,
    "user_id": 1,
    "date": "2024-11-21",
    "is_workout_goal_achieved": false,
    "has_walk_10min": true
  }
]
```

---

## 카드 API

### 1. POST /share_cards - 카드 저장

**인증 필요**: ✅

#### 요청
```
POST /share_cards
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "share_card": {
    "workout_id": 1,
    "card_date": "2024-11-22",
    "frame_theme_key": "theme_1",
    "image_url": "https://example.com/cards/card_123.jpg",
    "distance": 2500.5,
    "steps": 3500,
    "duration": 1800
  }
}
```

#### 처리 로직
```ruby
def create
  user = current_user

  # 1. Strong Parameters로 허용된 파라미터만 추출
  share_card_params = share_card_params_with_user(user)

  # 2. ShareCard 생성
  share_card = user.share_cards.build(share_card_params)

  # 3. 저장 시도
  if share_card.save
    render json: share_card, status: :created
  else
    render json: { errors: share_card.errors.full_messages }, status: :unprocessable_entity
  end
end
```

#### 응답 (201 Created)
```json
{
  "id": 1,
  "user_id": 1,
  "workout_id": 1,
  "card_date": "2024-11-22",
  "frame_theme_key": "theme_1",
  "image_url": "https://example.com/cards/card_123.jpg",
  "distance": "2500.5",
  "steps": 3500,
  "duration": 1800,
  "created_at": "2024-11-22T10:40:00.000Z",
  "updated_at": "2024-11-22T10:40:00.000Z"
}
```

#### 특징
- `workout_id`로 특정 Workout과 연결
- Workout의 스냅샷 데이터를 복사해서 저장 (원본 변경 시 영향 없음)

---

### 2. GET /share_cards - 카드 조회

**인증 필요**: ✅

#### 요청
```
GET /share_cards
Authorization: Bearer <JWT_TOKEN>

# 또는 특정 날짜만 조회
GET /share_cards?date=2024-11-22
Authorization: Bearer <JWT_TOKEN>
```

#### 처리 로직
```ruby
def index
  user = current_user
  date = params[:date]

  # 1. 날짜 파라미터에 따라 필터링
  share_cards = if date.present?
    # 특정 날짜의 카드만 조회
    user.share_cards.where(card_date: date).order(created_at: :desc)
  else
    # 모든 카드 조회 (최신순)
    user.share_cards.order(card_date: :desc, created_at: :desc)
  end

  render json: share_cards, status: :ok
end
```

#### 응답 (200 OK)
```json
[
  {
    "id": 1,
    "user_id": 1,
    "workout_id": 1,
    "card_date": "2024-11-22",
    "frame_theme_key": "theme_1",
    "image_url": "https://example.com/cards/card_123.jpg",
    "distance": "2500.5",
    "steps": 3500,
    "duration": 1800
  }
]
```

---

## 피드백 API

### 1. POST /feedbacks - 피드백 저장

**인증 필요**: ✅

#### 요청
```
POST /feedbacks
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "feedback": {
    "content": "앱이 정말 좋아요! 계속 사용하고 싶습니다.",
    "app_version": "1.0.0",
    "platform": "ios"
  }
}
```

#### 처리 로직
```ruby
def create
  user = current_user

  # 1. Strong Parameters로 허용된 파라미터만 추출
  feedback_params = feedback_params_with_user(user)

  # 2. Feedback 생성
  feedback = user.feedbacks.build(feedback_params)

  # 3. 저장 시도
  if feedback.save
    render json: feedback, status: :created
  else
    render json: { errors: feedback.errors.full_messages }, status: :unprocessable_entity
  end
end
```

#### 응답 (201 Created)
```json
{
  "id": 1,
  "user_id": 1,
  "content": "앱이 정말 좋아요! 계속 사용하고 싶습니다.",
  "app_version": "1.0.0",
  "platform": "ios",
  "created_at": "2024-11-22T11:00:00.000Z",
  "updated_at": "2024-11-22T11:00:00.000Z"
}
```

#### 유효성 검사
- `content`: 필수
- `platform`: 필수

---

## 공통 패턴 분석

### 1. 인증 처리
- `before_action :authenticate_user!`로 인증 필수
- `ApplicationController#current_user`로 현재 유저 가져오기
- 인증 실패 시 401 Unauthorized

### 2. Strong Parameters
- 모든 컨트롤러에서 `params.require(:resource).permit(...)` 사용
- 허용된 파라미터만 받아서 보안 강화

### 3. 에러 처리
- **400 Bad Request**: 필수 파라미터 누락
- **401 Unauthorized**: 인증 실패
- **404 Not Found**: 리소스를 찾을 수 없음
- **409 Conflict**: 중복 (login_id, provider+provider_id)
- **422 Unprocessable Entity**: 유효성 검사 실패
- **500 Internal Server Error**: 서버 오류

### 4. JSON 응답 형식
- 성공: 리소스 객체 또는 배열
- 실패: `{ error: "..." }` 또는 `{ errors: [...] }`

### 5. 데이터베이스 관계
- 모든 리소스는 `user_id`로 User와 연결
- `user.resources.build(...)`로 생성 시 `user_id` 자동 설정

---

## 주요 설계 결정사항

### 1. 영구 토큰 사용
- JWT 토큰에 만료 시간 없음 (`exp` 필드 없음)
- `JwtService.decode`에서 `verify_expiration: false` 설정

### 2. Private S3 객체
- Presigned PUT URL로 private 객체 업로드
- Presigned GET URL로 임시 접근 (1시간 유효)
- DB에는 `s3_key`만 저장

### 3. DailyWorkout 조회 전용
- 데이터가 없으면 기본값으로 메모리상 객체 생성
- 실제로 저장하지 않음

### 4. ShareCard는 스냅샷
- Workout 데이터를 복사해서 저장
- 원본 Workout 변경 시 영향 없음

---

**마지막 업데이트**: 2024-11-22

