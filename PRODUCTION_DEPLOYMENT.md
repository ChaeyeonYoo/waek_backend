# 프로덕션 배포 가이드

## 개요

이 문서는 waek_backend Rails API 서버를 프로덕션 Linux 서버에 배포하는 방법을 설명합니다.

## 사전 준비

### 1. AWS S3 설정 완료
- ✅ S3 버킷 생성: `waek-photo-bucket` (ap-northeast-2)
- ✅ IAM 사용자 생성: `waek-backend-s3-user`
- ✅ IAM 권한 설정: `s3:PutObject`, `s3:GetObject` on `waek-photo-bucket`

### 2. 서버 환경
- Linux 서버 (Ubuntu/CentOS 등)
- Ruby 3.3.5 설치
- PostgreSQL 설치 및 실행
- Nginx 설치 (리버스 프록시용)

## 배포 단계

### Step 1: 환경 변수 설정

서버에서 `.env` 파일 생성:

```bash
cd /path/to/waek_backend
cp config/aws_env.example .env
nano .env
```

`.env` 파일 내용:
```bash
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=waek-photo-bucket
```

파일 권한 설정:
```bash
chmod 600 .env  # 소유자만 읽기/쓰기 가능
```

### Step 2: systemd 서비스 파일 설정

```bash
# 서비스 파일 복사
sudo cp config/puma.service.example /etc/systemd/system/puma.service

# 파일 수정 (경로, 사용자명 등)
sudo nano /etc/systemd/system/puma.service
```

주요 수정 사항:
- `User=your-username` → 실제 사용자명
- `WorkingDirectory=/path/to/waek_backend` → 실제 프로젝트 경로
- `EnvironmentFile=/path/to/waek_backend/.env` → 실제 .env 파일 경로

서비스 활성화:
```bash
sudo systemctl daemon-reload
sudo systemctl enable puma
sudo systemctl start puma
```

### Step 3: 배포 실행

자동 배포 스크립트 사용:
```bash
./scripts/deploy.sh
```

또는 수동 배포:
```bash
# 1. Git에서 최신 코드 가져오기
git pull origin main

# 2. 의존성 설치
bundle install --deployment --without development test

# 3. 데이터베이스 마이그레이션
RAILS_ENV=production bundle exec rails db:migrate

# 4. Puma 재시작
sudo systemctl restart puma
```

### Step 4: 서버 상태 확인

```bash
# Health check
curl http://localhost:3000/up

# Puma 상태
sudo systemctl status puma

# 로그 확인
sudo journalctl -u puma -f
```

## S3 Presigned URL 테스트

### 로컬에서 테스트 (환경 변수 설정 후)

```bash
# .env 파일 생성
cat > .env << EOF
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=waek-photo-bucket
EOF

# 서버 재시작
rails server
```

### API 테스트

```bash
# 1. 토큰 발급
TOKEN=$(curl -s -X POST http://localhost:3000/auth/social/signup \
  -H "Content-Type: application/json" \
  -d '{"provider":"kakao","provider_id":"test","username":"test","nickname":"테스트","profile_image_code":1}' \
  | jq -r '.token.access_token')

# 2. Presigned URL 발급
curl -X POST http://localhost:3000/uploads/presigned_url \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_type":"image/png"}'
```

성공 응답:
```json
{
  "upload_url": "https://waek-photo-bucket.s3.ap-northeast-2.amazonaws.com/workouts/...",
  "photo_key": "workouts/1732262400_abc123_walk_1234567890.png",
  "expires_in": 600
}
```

## 문제 해결

### Puma가 시작되지 않을 때

```bash
# 로그 확인
sudo journalctl -u puma -n 50

# 환경 변수 확인
sudo systemctl show puma | grep Environment

# 수동 실행 테스트
cd /path/to/waek_backend
RAILS_ENV=production bundle exec puma -C config/puma.rb
```

### S3 연결 실패

```bash
# 환경 변수 확인
cd /path/to/waek_backend
RAILS_ENV=production bundle exec rails runner "puts ENV['AWS_S3_BUCKET']"

# Rails 콘솔에서 테스트
RAILS_ENV=production bundle exec rails console
> S3PresignedUrlService.s3_client.list_buckets
```

### 데이터베이스 연결 실패

```bash
# database.yml 확인
cat config/database.yml

# PostgreSQL 연결 확인
psql -U waek_backend -d waek_backend_production -h localhost
```

## 보안 체크리스트

- [ ] `.env` 파일이 Git에 커밋되지 않았는지 확인
- [ ] `.env` 파일 권한이 600인지 확인
- [ ] IAM 사용자 권한이 최소 권한인지 확인
- [ ] S3 버킷이 private로 설정되어 있는지 확인
- [ ] 프로덕션 로그에 자격 증명이 포함되지 않는지 확인

## 유지보수

### 정기적인 작업

1. **코드 업데이트**: `./scripts/deploy.sh` 실행
2. **로그 확인**: `sudo journalctl -u puma -f`
3. **디스크 공간 확인**: `df -h`
4. **데이터베이스 백업**: 정기적으로 백업 수행

### 모니터링

- Health check 엔드포인트: `GET /up`
- 로그 모니터링: `tail -f log/production.log`
- Puma 상태: `sudo systemctl status puma`

## 추가 리소스

- `DEPLOYMENT_CHECKLIST.md` - 상세 배포 체크리스트
- `S3_SETUP_GUIDE.md` - S3 설정 가이드
- `config/puma.service.example` - systemd 서비스 파일 예제
- `scripts/deploy.sh` - 자동 배포 스크립트
- `scripts/restart_puma.sh` - Puma 재시작 스크립트

