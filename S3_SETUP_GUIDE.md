# AWS S3 Presigned URL 설정 가이드

## 1. AWS S3 버킷 생성

### AWS 콘솔에서 버킷 생성

1. AWS 콘솔 접속 → S3 서비스 선택
2. "버킷 만들기" 클릭
3. 버킷 설정:
   - **버킷 이름**: `waek-backend-production` (또는 원하는 이름)
   - **리전**: `ap-northeast-2` (서울)
   - **객체 소유권**: ACL 비활성화 (권장)
   - **퍼블릭 액세스 차단**: **모든 퍼블릭 액세스 차단** (중요! private 유지)
   - 버전 관리: 필요시 활성화
   - 암호화: 기본값 사용

4. 버킷 생성 완료

## 2. IAM 사용자 생성 및 권한 설정

### IAM 사용자 생성

1. AWS 콘솔 → IAM → 사용자 → 사용자 추가
2. 사용자 이름: `waek-s3-user` (또는 원하는 이름)
3. 액세스 유형: **프로그래밍 방식 액세스** 선택
4. 권한 설정: **기존 정책 직접 연결**
   - `AmazonS3FullAccess` 선택 (또는 커스텀 정책 생성)

### 커스텀 정책 (권장 - 최소 권한)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::waek-backend-production/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::waek-backend-production"
    }
  ]
}
```

5. 사용자 생성 완료 후 **액세스 키 ID**와 **비밀 액세스 키** 저장 (한 번만 표시됨!)

## 3. 환경 변수 설정

### 로컬 개발 환경 (.env 파일)

프로젝트 루트에 `.env` 파일 생성:

```bash
# AWS S3 설정
AWS_ACCESS_KEY_ID=your-access-key-id-here
AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=waek-backend-production
```

### 실제 서버 환경

서버에서 환경 변수 설정:

```bash
# .env 파일 또는 시스템 환경 변수로 설정
export AWS_ACCESS_KEY_ID=your-access-key-id-here
export AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
export AWS_REGION=ap-northeast-2
export AWS_S3_BUCKET=waek-backend-production
```

또는 `.env` 파일 사용 (dotenv-rails가 자동으로 로드)

## 4. 버킷 정책 확인 (Private 유지)

버킷이 **private**로 유지되는지 확인:

1. S3 콘솔 → 버킷 선택 → 권한 탭
2. **퍼블릭 액세스 차단** 설정 확인:
   - ✅ 모든 퍼블릭 액세스 차단
3. **버킷 정책**에 public-read 정책이 없어야 함

## 5. 로컬 테스트

### 환경 변수 설정 후 테스트

```bash
# .env 파일 생성
cat > .env << EOF
AWS_ACCESS_KEY_ID=your-key-here
AWS_SECRET_ACCESS_KEY=your-secret-here
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=waek-backend-production
EOF

# 서버 재시작
rails server
```

### API 테스트

```bash
# 1. 토큰 발급
TOKEN=$(curl -s -X POST http://localhost:3000/auth/social/signup \
  -H "Content-Type: application/json" \
  -d '{"provider":"kakao","provider_id":"test_123","username":"testuser","nickname":"테스트","profile_image_code":1}' \
  | jq -r '.token.access_token')

# 2. Presigned URL 발급
curl -X POST http://localhost:3000/uploads/presigned_url \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_type":"image/png"}'
```

응답 예시:
```json
{
  "upload_url": "https://waek-backend-production.s3.ap-northeast-2.amazonaws.com/workouts/...",
  "photo_key": "workouts/1732262400_abc123_walk_1234567890.png",
  "expires_in": 600
}
```

## 6. 실제 서버 배포 시

### 환경 변수 설정 방법

**옵션 1: .env 파일 사용 (권장)**
```bash
# 서버에서
cd /path/to/waek_backend
nano .env  # 환경 변수 입력
```

**옵션 2: 시스템 환경 변수**
```bash
# /etc/environment 또는 ~/.bashrc에 추가
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=ap-northeast-2
export AWS_S3_BUCKET=waek-backend-production
```

**옵션 3: systemd 서비스 파일**
```ini
[Service]
Environment="AWS_ACCESS_KEY_ID=..."
Environment="AWS_SECRET_ACCESS_KEY=..."
Environment="AWS_REGION=ap-northeast-2"
Environment="AWS_S3_BUCKET=waek-backend-production"
```

## 7. 보안 주의사항

⚠️ **중요:**
- `.env` 파일은 **절대 Git에 커밋하지 마세요**
- `.gitignore`에 `.env` 추가 확인
- 실제 서버에서는 환경 변수를 안전하게 관리
- IAM 사용자 권한은 최소 권한 원칙 적용

## 8. 문제 해결

### 에러: MissingCredentialsError
- 환경 변수가 제대로 설정되었는지 확인
- 서버 재시작 필요할 수 있음

### 에러: AccessDenied
- IAM 사용자 권한 확인
- 버킷 이름이 정확한지 확인

### Presigned URL이 작동하지 않음
- 버킷 리전과 AWS_REGION이 일치하는지 확인
- 버킷 이름이 정확한지 확인

