# 서버 실행을 위한 현재 상황 요약

## 📋 프로젝트 정보
- **프로젝트명**: waek_backend (왹왹이 백엔드)
- **프레임워크**: Ruby on Rails 7.1.6 (API only 모드)
- **Ruby 버전**: 3.3.5 ✅ (설치 완료)
- **데이터베이스**: PostgreSQL 14.18 ✅ (설치 완료, 하지만 실행 중 아님)

## ✅ 완료된 항목
1. **Ruby 설치**: 3.3.5 버전 설치 완료
2. **PostgreSQL 설치**: 14.18 버전 설치 완료 (Homebrew)
3. **의존성 설치**: `bundle install` 완료 (Gemfile의 모든 gem 설치됨)
4. **환경 변수**: `.env` 파일 존재 (JWT_SECRET 설정됨)
5. **데이터베이스 스키마**: 마이그레이션 파일 존재 (5개 테이블: users, workouts, daily_workouts, share_cards, feedbacks)

## ❌ 해결해야 할 문제

### 1. PostgreSQL 서버가 실행되지 않음
- **상태**: PostgreSQL 14.18은 설치되어 있지만 서버가 실행 중이 아님
- **증상**: 
  ```
  connection to server on socket "/tmp/.s.PGSQL.5432" failed: No such file or directory
  ```
- **원인**: PostgreSQL 서버 프로세스가 시작되지 않음
- **해결 방법**:
  ```bash
  # 방법 1: Homebrew services로 시작
  brew services start postgresql@14
  
  # 방법 2: 수동으로 시작
  pg_ctl -D /opt/homebrew/var/postgresql@14 start
  
  # 방법 3: PostgreSQL이 다른 경로에 있다면
  # 데이터 디렉토리 찾기
  find /opt/homebrew/var -name "postgres*" -type d
  ```

### 2. 데이터베이스 생성 및 마이그레이션 필요
- PostgreSQL 서버가 실행되면 다음 명령어 실행 필요:
  ```bash
  bundle exec rails db:create      # 데이터베이스 생성
  bundle exec rails db:migrate     # 마이그레이션 실행
  ```

## 🚀 서버 실행 단계 (PostgreSQL 실행 후)

1. **PostgreSQL 서버 시작**
   ```bash
   brew services start postgresql@14
   ```

2. **데이터베이스 생성 및 마이그레이션**
   ```bash
   cd /Users/chaeyeon/RubymineProjects/waek_backend
   bundle exec rails db:create
   bundle exec rails db:migrate
   ```

3. **서버 실행**
   ```bash
   bundle exec rails server
   # 또는
   bundle exec rails s
   ```

4. **서버 확인**
   - 서버는 기본적으로 `http://localhost:3000`에서 실행됩니다
   - Health check: `curl http://localhost:3000/up`

## 📝 현재 프로젝트 구조
```
waek_backend/
├── app/
│   ├── controllers/     # API 컨트롤러들 (auth, workouts, daily_workouts, share_cards, feedbacks)
│   └── models/          # 모델들 (User, Workout, DailyWorkout, ShareCard, Feedback)
├── config/
│   ├── database.yml     # PostgreSQL 설정
│   ├── routes.rb        # API 라우팅
│   └── initializers/
│       └── cors.rb      # CORS 설정 (모든 origin 허용)
├── db/
│   ├── migrate/         # 마이그레이션 파일들 (5개)
│   └── schema.rb        # 현재 스키마 정의
├── lib/
│   └── jwt_service.rb   # JWT 토큰 발급/검증
└── .env                 # 환경 변수 (JWT_SECRET)
```

## 🔌 API 엔드포인트 (서버 실행 후 사용 가능)
- `POST /auth/social_login` - 소셜 로그인
- `POST /workouts` - 산책 기록 저장
- `GET /workouts?date=YYYY-MM-DD` - 산책 기록 조회
- `GET /daily_workouts/:date` - 일일 요약 조회
- `GET /daily_workouts?start_date=...&end_date=...` - 일일 요약 목록
- `POST /share_cards` - 카드 저장
- `GET /share_cards?date=YYYY-MM-DD` - 카드 조회
- `POST /feedbacks` - 피드백 저장

## ⚠️ 주의사항
1. PostgreSQL 서버가 실행되어야 데이터베이스 작업이 가능합니다
2. 데이터베이스가 생성되어야 마이그레이션을 실행할 수 있습니다
3. 서버 실행 전에 반드시 `bundle exec rails db:create`와 `bundle exec rails db:migrate`를 실행해야 합니다

## 🎯 다음 단계
1. **PostgreSQL 서버 시작** (가장 우선)
2. 데이터베이스 생성 및 마이그레이션
3. 서버 실행
4. API 테스트

---
*생성일: 2024-11-15*

