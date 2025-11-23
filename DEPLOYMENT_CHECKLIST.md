# 프로덕션 배포 체크리스트

## 1. 서버 환경 변수 설정

### 방법 A: .env 파일 사용 (권장)

```bash
# 서버에서
cd /path/to/waek_backend
cp config/aws_env.example .env
nano .env  # 환경 변수 입력
```

`.env` 파일 내용:
```bash
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=waek-photo-bucket
```

### 방법 B: systemd 서비스 파일에 환경 변수 추가

`/etc/systemd/system/puma.service` 파일에 추가:
```ini
[Service]
EnvironmentFile=/path/to/waek_backend/.env
```

또는 직접 환경 변수 지정:
```ini
[Service]
Environment="AWS_ACCESS_KEY_ID=your-key"
Environment="AWS_SECRET_ACCESS_KEY=your-secret"
Environment="AWS_REGION=ap-northeast-2"
Environment="AWS_S3_BUCKET=waek-photo-bucket"
```

## 2. 배포 스크립트 실행 권한 부여

```bash
chmod +x scripts/deploy.sh
chmod +x scripts/restart_puma.sh
```

## 3. 배포 실행

```bash
./scripts/deploy.sh
```

또는 수동으로:

```bash
# 1. Git에서 최신 코드 가져오기
git pull origin main

# 2. 의존성 설치
bundle install --deployment --without development test

# 3. 데이터베이스 마이그레이션
RAILS_ENV=production bundle exec rails db:migrate

# 4. Puma 재시작
sudo systemctl restart puma
# 또는
./scripts/restart_puma.sh
```

## 4. 서버 상태 확인

```bash
# Health check
curl http://localhost:3000/up

# Puma 상태
sudo systemctl status puma

# 로그 확인
sudo journalctl -u puma -f
# 또는
tail -f log/production.log
```

## 5. S3 Presigned URL 테스트

```bash
# 1. 토큰 발급
TOKEN=$(curl -s -X POST http://localhost:3000/auth/social/signup \
  -H "Content-Type: application/json" \
  -d '{"provider":"kakao","provider_id":"test","username":"test","nickname":"테스트","profile_image_code":1}' \
  | jq -r '.token.access_token')

# 2. Presigned URL 발급 테스트
curl -X POST http://localhost:3000/uploads/presigned_url \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_type":"image/png"}'
```

성공 응답 예시:
```json
{
  "upload_url": "https://waek-photo-bucket.s3.ap-northeast-2.amazonaws.com/workouts/...",
  "photo_key": "workouts/1732262400_abc123_walk_1234567890.png",
  "expires_in": 600
}
```

## 6. 문제 해결

### Puma가 재시작되지 않을 때

```bash
# systemd 상태 확인
sudo systemctl status puma

# 수동 재시작
sudo systemctl restart puma

# 로그 확인
sudo journalctl -u puma -n 50
```

### 환경 변수가 로드되지 않을 때

```bash
# .env 파일 확인
cat .env

# systemd 서비스 파일에 EnvironmentFile 확인
sudo systemctl show puma | grep EnvironmentFile

# 환경 변수 테스트
RAILS_ENV=production bundle exec rails runner "puts ENV['AWS_S3_BUCKET']"
```

### S3 연결 실패 시

```bash
# 환경 변수 확인
echo $AWS_ACCESS_KEY_ID
echo $AWS_REGION
echo $AWS_S3_BUCKET

# Rails 콘솔에서 테스트
RAILS_ENV=production bundle exec rails console
> S3PresignedUrlService.s3_client.list_buckets
```

## 7. 보안 확인

- [ ] `.env` 파일이 Git에 커밋되지 않았는지 확인
- [ ] `.gitignore`에 `.env`가 포함되어 있는지 확인
- [ ] 서버의 `.env` 파일 권한이 적절한지 확인 (600 권장)
- [ ] IAM 사용자 권한이 최소 권한인지 확인

