# AWS S3 버킷 설정을 위한 프롬프트

아래 내용을 ChatGPT에 복사해서 붙여넣으면 S3 버킷 설정을 도와받을 수 있습니다.

---

## 프로젝트 개요

**프로젝트**: 왹왹이(waek) iOS 앱 백엔드  
**기술 스택**: Ruby on Rails 7.1.6 (API only)  
**목적**: 사용자가 산책 기록과 함께 사진을 업로드할 수 있도록 S3 Presigned URL 기능 구현

---

## 현재 구현 상태

### 1. S3 Presigned URL 서비스 (`lib/s3_presigned_url_service.rb`)

```ruby
class S3PresignedUrlService
  require 'aws-sdk-s3'
  require 'securerandom'

  # S3 클라이언트 초기화
  def self.s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV.fetch('AWS_REGION', 'ap-northeast-2')
    )
  end

  # Presigned URL 생성
  def self.generate_presigned_url(file_name:, content_type:, expires_in: 3600)
    bucket = ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
    timestamp = Time.current.to_i
    s3_key = "workouts/#{timestamp}_#{SecureRandom.hex(8)}_#{file_name}"

    signer = Aws::S3::Presigner.new(client: s3_client)
    url = signer.presigned_url(
      :put_object,
      bucket: bucket,
      key: s3_key,
      acl: 'public-read',  # 업로드된 파일을 공개 읽기 가능하게
      content_type: content_type,
      expires_in: expires_in
    )

    {
      url: url,
      key: s3_key,
      expires_at: Time.current + expires_in.seconds,
      bucket: bucket
    }
  end

  # 공개 URL 생성
  def self.public_url(s3_key)
    bucket = ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
    region = ENV.fetch('AWS_REGION', 'ap-northeast-2')
    "https://#{bucket}.s3.#{region}.amazonaws.com/#{s3_key}"
  end
end
```

### 2. API 엔드포인트

#### Presigned URL 발급
- **엔드포인트**: `POST /workouts/presigned_url`
- **인증**: 필요 (JWT Bearer Token)
- **Request**:
  ```json
  {
    "file_name": "workout_photo.jpg",
    "content_type": "image/jpeg"
  }
  ```
- **Response**:
  ```json
  {
    "presigned_url": "https://s3.amazonaws.com/bucket/key?...",
    "s3_key": "workouts/1234567890_abc123_workout_photo.jpg",
    "expires_at": "2024-11-22T14:30:00Z",
    "public_url": "https://bucket.s3.region.amazonaws.com/workouts/..."
  }
  ```

#### 사진과 함께 기록 저장
- **엔드포인트**: `POST /workouts/with_image`
- **인증**: 필요 (JWT Bearer Token)
- **Request**:
  ```json
  {
    "workout": {
      "workout_date": "2024-11-22",
      "started_at": "2024-11-22T10:00:00Z",
      "ended_at": "2024-11-22T10:30:00Z",
      "distance": 2500.5,
      "steps": 3500,
      "duration": 1800,
      "calories": 120.5,
      "image_url": "https://bucket.s3.region.amazonaws.com/workouts/...",
      "s3_key": "workouts/1234567890_abc123_workout_photo.jpg"  // 선택사항
    }
  }
  ```

### 3. 환경 변수 설정

`.env` 파일에 다음 변수들이 필요합니다:

```bash
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=waek-backend-production
```

### 4. S3 설정 파일 (`config/storage.yml`)

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY_ID") { Rails.application.credentials.dig(:aws, :access_key_id) } %>
  secret_access_key: <%= ENV.fetch("AWS_SECRET_ACCESS_KEY") { Rails.application.credentials.dig(:aws, :secret_access_key) } %>
  region: <%= ENV.fetch("AWS_REGION", "ap-northeast-2") %>
  bucket: <%= ENV.fetch("AWS_S3_BUCKET", "waek-backend-#{Rails.env}") %>
```

---

## 필요한 작업

### 1. AWS S3 버킷 생성
- 버킷 이름: `waek-backend-production` (또는 원하는 이름)
- 리전: `ap-northeast-2` (Seoul) 또는 원하는 리전
- Public Access: 사진을 공개로 읽을 수 있도록 설정 필요

### 2. CORS 설정
iOS 앱에서 직접 S3에 업로드할 수 있도록 CORS 설정이 필요합니다.

**필요한 CORS 설정:**
```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "HEAD"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
```

### 3. 버킷 정책 설정
업로드된 사진을 공개로 읽을 수 있도록 버킷 정책이 필요합니다.

**필요한 버킷 정책:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::waek-backend-production/*"
        }
    ]
}
```

### 4. IAM 사용자 및 Access Key 생성
- IAM 사용자 생성 (예: `waek-backend-s3-user`)
- S3 접근 권한 부여 (AmazonS3FullAccess 또는 필요한 권한만)
- Access Key ID와 Secret Access Key 생성

---

## 요청사항

다음 작업들을 단계별로 도와주세요:

1. **AWS S3 버킷 생성 가이드**
   - AWS 콘솔에서 버킷 생성하는 방법
   - 버킷 이름 규칙 및 리전 선택 가이드
   - Public Access 설정 방법

2. **CORS 설정 가이드**
   - AWS 콘솔에서 CORS 설정하는 방법
   - 위의 CORS 설정을 적용하는 방법

3. **버킷 정책 설정 가이드**
   - 버킷 정책 편집 방법
   - 위의 버킷 정책을 적용하는 방법
   - 보안 고려사항

4. **IAM 설정 가이드**
   - IAM 사용자 생성 방법
   - 적절한 권한 부여 방법
   - Access Key 생성 및 안전한 관리 방법

5. **테스트 방법**
   - 버킷이 제대로 설정되었는지 확인하는 방법
   - Presigned URL이 제대로 작동하는지 테스트하는 방법

6. **비용 최적화 팁**
   - S3 비용 절감 방법
   - Lifecycle 규칙 설정
   - 적절한 스토리지 클래스 선택

---

## 추가 정보

- **파일 업로드 플로우**:
  1. iOS 앱 → `POST /workouts/presigned_url` (Presigned URL 요청)
  2. 백엔드 → Presigned URL 반환
  3. iOS 앱 → Presigned URL로 S3에 직접 업로드 (PUT 요청)
  4. iOS 앱 → `POST /workouts/with_image` (사진 URL + 기록 데이터)

- **S3 키 형식**: `workouts/{timestamp}_{random}_{filename}`
- **Presigned URL 유효 시간**: 1시간 (3600초)
- **파일 접근 권한**: Public Read (업로드된 파일은 누구나 읽을 수 있음)

---

위 정보를 바탕으로 AWS S3 버킷 설정을 단계별로 안내해주세요.

