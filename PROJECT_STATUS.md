# 왹왹이(waek) 백엔드 프로젝트 현황 문서

## 📋 프로젝트 개요

**프로젝트명**: 왹왹이 (waek) - 걷기/산책 습관 앱  
**백엔드**: Ruby on Rails (API only)  
**데이터베이스**: PostgreSQL  
**프론트엔드**: iOS 앱 (Swift, HealthKit 연동)  
**목적**: 실제 출시할 모바일 앱의 백엔드 API 서버

---

## ✅ 완료된 작업

### 1. 프로젝트 초기 설정
- ✅ Rails 7.1.6 API 모드 프로젝트 생성
- ✅ PostgreSQL 데이터베이스 설정
- ✅ 필요한 Gem 설치 (JWT, rack-cors, dotenv-rails 등)
- ✅ CORS 설정 (iOS 앱에서 API 호출 허용)

### 2. 데이터베이스 스키마 설계 및 구현
- ✅ 5개 테이블 생성 완료:
  - `users` - 유저 정보 (소셜 로그인 기반)
  - `workouts` - 산책 세션 기록
  - `daily_workouts` - 하루 단위 요약
  - `share_cards` - 운동 결과 카드 스냅샷
  - `feedbacks` - 유저 피드백
- ✅ 모든 마이그레이션 실행 완료
- ✅ Foreign Key(외래키) 및 인덱스 설정 완료

### 3. 모델(Model) 구현
- ✅ 5개 모델 파일 생성 및 관계 설정:
  - `User` - has_many :workouts, :daily_workouts, :share_cards, :feedbacks
  - `Workout` - belongs_to :user, has_many :share_cards
  - `DailyWorkout` - belongs_to :user
  - `ShareCard` - belongs_to :user, belongs_to :workout
  - `Feedback` - belongs_to :user
- ✅ 유효성 검사(Validations) 설정 완료

### 4. JWT 인증 시스템 구현
- ✅ `JwtService` 클래스 생성 (토큰 발급/검증)
  - 위치: `lib/jwt_service.rb`
  - 메서드: `encode(user_id)`, `decode(token)`
- ✅ `ApplicationController`에 인증 로직 추가:
  - `current_user` - 현재 로그인한 유저 반환
  - `authenticate_user!` - 인증 필수 체크
- ✅ 토큰 만료 시간: 30일

### 5. API 컨트롤러 구현
- ✅ `AuthController` - 소셜 로그인 API
- ✅ `WorkoutsController` - 산책 기록 저장/조회
- ✅ `DailyWorkoutsController` - 일일 요약 조회
- ✅ `ShareCardsController` - 카드 저장/조회
- ✅ `FeedbacksController` - 피드백 저장

### 6. 라우팅(Routes) 설정
- ✅ 모든 API 엔드포인트 정의 완료
- ✅ RESTful API 구조 적용

### 7. 테스트 완료
- ✅ 로컬 서버에서 모든 API 테스트 완료
- ✅ curl을 사용한 실제 요청/응답 확인 완료

---

## 🛠 기술 스택

### 백엔드
- **Ruby**: 3.3.5
- **Rails**: 7.1.6 (API only 모드)
- **데이터베이스**: PostgreSQL
- **인증**: JWT (JSON Web Token)
- **서버**: Puma

### 주요 Gem
- `pg` - PostgreSQL 어댑터
- `jwt` - JWT 토큰 처리
- `rack-cors` - CORS 처리
- `dotenv-rails` - 환경 변수 관리
- `rspec-rails` - 테스트 프레임워크

---

## 📊 데이터베이스 스키마

### Users 테이블
```ruby
- id (bigint, PK)
- login_id (string)
- nickname (string, required)
- profile_image_key (integer) # 미리 제공된 사진 중 선택
- provider (integer, required) # 1: apple, 2: kakao, 3: google
- provider_user_id (string, required)
- social_email (string)
- is_premium (boolean, default: false)
- created_at, updated_at
- 인덱스: (provider, provider_user_id) unique
```

### Workouts 테이블
```ruby
- id (bigint, PK)
- user_id (bigint, FK → users.id)
- workout_date (date, required)
- started_at (datetime, required)
- ended_at (datetime, required)
- distance (decimal, precision: 10, scale: 2) # 미터 단위
- steps (integer)
- duration (integer, required) # 초 단위
- calories (decimal, precision: 8, scale: 2)
- created_at, updated_at
- 인덱스: workout_date, (user_id, workout_date)
```

### DailyWorkouts 테이블
```ruby
- id (bigint, PK)
- user_id (bigint, FK → users.id)
- date (date, required)
- is_workout_goal_achieved (boolean, default: false)
- has_walk_10min (boolean, default: false)
- created_at, updated_at
- 인덱스: (user_id, date) unique # 하루에 한 줄만 존재
```

### ShareCards 테이블
```ruby
- id (bigint, PK)
- user_id (bigint, FK → users.id)
- workout_id (bigint, FK → workouts.id)
- card_date (date, required)
- frame_theme_key (string)
- image_url (string)
- distance (decimal) # Workout에서 복사한 스냅샷
- steps (integer)
- duration (integer)
- created_at, updated_at
- 인덱스: card_date, (user_id, card_date)
```

### Feedbacks 테이블
```ruby
- id (bigint, PK)
- user_id (bigint, FK → users.id)
- content (text, required)
- app_version (string)
- platform (string, required) # "ios"
- created_at, updated_at
```

---

## 🔌 API 엔드포인트

### 인증
- `POST /auth/social_login` - 소셜 로그인
  - Request: `{ provider, provider_user_id, nickname, social_email?, profile_image_key? }`
  - Response: `{ token, user: { id, nickname, profile_image_key, provider, is_premium } }`

### 산책 기록
- `POST /workouts` - 산책 기록 저장 (인증 필요)
  - Request: `{ workout: { workout_date, started_at, ended_at, distance, steps, duration, calories? } }`
  - Response: `{ id, user_id, workout_date, ... }`
- `GET /workouts?date=YYYY-MM-DD` - 산책 기록 조회 (인증 필요)
  - Response: `[{ id, workout_date, distance, steps, ... }]`

### 일일 요약
- `GET /daily_workouts/:date` - 특정 날짜의 일일 요약 (인증 필요)
  - Response: `{ id, date, is_workout_goal_achieved, has_walk_10min }`
- `GET /daily_workouts?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` - 일일 요약 목록 (인증 필요)
  - Response: `[{ id, date, ... }]`

### 카드
- `POST /share_cards` - 카드 저장 (인증 필요)
  - Request: `{ share_card: { workout_id, card_date, frame_theme_key, image_url?, distance, steps, duration } }`
  - Response: `{ id, workout_id, card_date, ... }`
- `GET /share_cards?date=YYYY-MM-DD` - 카드 조회 (인증 필요)
  - Response: `[{ id, card_date, frame_theme_key, ... }]`

### 피드백
- `POST /feedbacks` - 피드백 저장 (인증 필요)
  - Request: `{ feedback: { content, app_version?, platform } }`
  - Response: `{ id, content, platform, ... }`

---

## 📁 주요 파일 구조

```
waek_backend/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb    # 인증 헬퍼 (current_user, authenticate_user!)
│   │   ├── auth_controller.rb           # 소셜 로그인
│   │   ├── workouts_controller.rb       # 산책 기록
│   │   ├── daily_workouts_controller.rb # 일일 요약
│   │   ├── share_cards_controller.rb    # 카드
│   │   └── feedbacks_controller.rb      # 피드백
│   └── models/
│       ├── user.rb
│       ├── workout.rb
│       ├── daily_workout.rb
│       ├── share_card.rb
│       └── feedback.rb
├── config/
│   ├── routes.rb                        # 라우팅 설정
│   ├── database.yml                     # 데이터베이스 설정
│   └── initializers/
│       └── cors.rb                      # CORS 설정
├── db/
│   ├── migrate/                         # 마이그레이션 파일들
│   └── schema.rb                        # 현재 스키마
├── lib/
│   └── jwt_service.rb                   # JWT 토큰 발급/검증
└── Gemfile                              # 의존성 관리
```

---

## 🔐 인증 방식

### JWT 토큰 기반 인증
- 토큰 발급: `JwtService.encode(user_id)`
- 토큰 검증: `JwtService.decode(token)` → user_id 반환
- 토큰 만료: 30일
- 헤더 형식: `Authorization: Bearer <token>`

### 인증이 필요한 API
- 모든 API는 `before_action :authenticate_user!` 사용
- 예외: `POST /auth/social_login` (로그인 전이므로 인증 불필요)

---

## ⚙️ 환경 설정

### 환경 변수 (.env 파일)
```
JWT_SECRET=your-secret-key-change-this-in-production
```

### 데이터베이스
- Development: `waek_backend_development`
- Test: `waek_backend_test`
- Production: `waek_backend_production` (환경 변수로 설정)

---

## 🧪 테스트 결과

### 로컬 테스트 완료
- ✅ 소셜 로그인 API 테스트 성공
- ✅ Workout 저장/조회 테스트 성공
- ✅ DailyWorkout 조회 테스트 성공
- ✅ ShareCard 저장 테스트 성공
- ✅ Feedback 저장 테스트 성공

### 테스트 방법
```bash
# 서버 실행
bundle exec rails server

# 테스트 예시
curl -X POST http://localhost:3000/auth/social_login \
  -H "Content-Type: application/json" \
  -d '{"provider": 1, "provider_user_id": "test123", "nickname": "테스트유저"}'
```

---

## 📝 주요 설계 결정사항

### 1. Provider와 Profile Image Key를 Integer로 사용
- `provider`: 1 (apple), 2 (kakao), 3 (google)
- `profile_image_key`: 미리 제공된 사진의 번호
- 이유: 저장 공간 절약 및 성능 향상

### 2. DailyWorkout은 조회 전용
- Workout 저장 시 자동 업데이트 로직은 아직 미구현
- 현재는 조회만 가능 (없으면 기본값 반환)

### 3. ShareCard는 Workout의 스냅샷 저장
- Workout 데이터를 복사해서 저장 (원본 변경 시 영향 없음)

---

## 🚀 다음 단계 (미완료 작업)

### 우선순위 높음
- [ ] DailyWorkout 자동 업데이트 로직 (Workout 저장 시)
- [ ] 에러 처리 개선 (표준화된 에러 응답 형식)
- [ ] 프로덕션 환경 배포 (Render/Railway/AWS)

### 우선순위 중간
- [ ] API 문서화 (Swagger/Postman)
- [ ] 로깅 설정
- [ ] 모니터링 설정

### 우선순위 낮음
- [ ] 테스트 코드 작성 (RSpec)
- [ ] 성능 최적화
- [ ] 캐싱 전략

---

## 📞 연락 및 협업

### iOS 개발자와의 협업
- API 엔드포인트: 위의 API 엔드포인트 섹션 참조
- 인증: JWT 토큰을 Authorization 헤더에 포함
- 테스트: 로컬 서버 (`http://localhost:3000`) 또는 배포된 서버 URL 사용

### 개발 환경
- 로컬 개발: `rails server` 실행 후 `localhost:3000` 사용
- 배포: 아직 미배포 (Render/Railway 등 고려 중)

---

## 💡 참고사항

1. **데이터베이스**: PostgreSQL 사용 중 (로컬 개발 환경)
2. **인증**: JWT 토큰 방식, 30일 만료
3. **CORS**: 개발 환경에서는 모든 origin 허용 (프로덕션에서는 제한 필요)
4. **에러 처리**: 기본적인 에러 응답만 구현 (개선 필요)
5. **로깅**: 기본 Rails 로깅 사용 중

---

## 📅 프로젝트 진행 상황

**현재 상태**: 기본 API 구현 완료, 로컬 테스트 완료  
**다음 마일스톤**: 프로덕션 배포 및 iOS 앱 연동 테스트  
**목표**: 실제 앱 스토어 출시를 위한 안정적인 백엔드 서버 구축

---

*마지막 업데이트: 2024-11-15*




