# ChatGPT용 AWS S3 Presigned URL 설정 프롬프트

아래 내용을 그대로 ChatGPT에 복사해서 붙여넣으세요.

---

You are an AWS expert helping me set up S3 for a Ruby on Rails API backend.

## Project Context

I have a **Ruby on Rails 7.1 API-only backend** for an iOS app called "waek". The app needs to handle private image uploads using S3 Presigned URLs.

## Current Implementation

### Code Structure

**Service Class** (`lib/s3_presigned_url_service.rb`):
```ruby
class S3PresignedUrlService
  require 'aws-sdk-s3'
  require 'securerandom'

  def self.s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV.fetch('AWS_REGION', 'ap-northeast-2')
    )
  end

  def self.generate_presigned_url(file_name:, content_type:, expires_in: 3600)
    bucket = ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
    timestamp = Time.current.to_i
    s3_key = "workouts/#{timestamp}_#{SecureRandom.hex(8)}_#{file_name}"

    signer = Aws::S3::Presigner.new(client: s3_client)
    url = signer.presigned_url(
      :put_object,
      bucket: bucket,
      key: s3_key,
      content_type: content_type,
      expires_in: expires_in
      # No ACL - objects remain private
    )

    {
      url: url,
      key: s3_key,
      expires_at: Time.current + expires_in.seconds,
      bucket: bucket
    }
  rescue Aws::Errors::ServiceError => e
    Rails.logger.error "S3 Presigned URL 생성 실패: #{e.message}"
    nil
  end

  def self.presigned_get_url(s3_key, expires_in: 3600)
    return nil if s3_key.blank?
    bucket = ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
    signer = Aws::S3::Presigner.new(client: s3_client)
    signer.presigned_url(
      :get_object,
      bucket: bucket,
      key: s3_key,
      expires_in: expires_in
    )
  rescue Aws::Errors::ServiceError => e
    Rails.logger.error "S3 Presigned GET URL 생성 실패: #{e.message}"
    nil
  end
end
```

**API Endpoint** (`POST /uploads/presigned_url`):
- Accepts: `content_type` (e.g., "image/png", "image/jpeg")
- Returns: `upload_url` (presigned PUT URL), `photo_key` (S3 key), `expires_in` (600 seconds)
- Auto-generates file name based on content_type

## Requirements

### 1. S3 Bucket Setup
- **Bucket name**: `waek-backend-production` (or suggest a better name)
- **Region**: `ap-northeast-2` (Seoul, South Korea)
- **Privacy**: **ALL objects must remain PRIVATE** (no public-read ACL, no public bucket policy)
- **Purpose**: Store user-uploaded walk photos (sensitive: contains location, faces, home surroundings)

### 2. IAM User Setup
- Create an IAM user for programmatic access
- **Minimum required permissions** for:
  - Generating presigned PUT URLs (for uploads)
  - Generating presigned GET URLs (for downloads)
  - No need for public access or bucket listing in production

### 3. Environment Variables Needed
The code expects these environment variables:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (defaults to "ap-northeast-2" if not set)
- `AWS_S3_BUCKET` (defaults to "waek-backend-{Rails.env}" if not set)

## What I Need Help With

1. **Step-by-step guide** to create the S3 bucket with proper privacy settings
2. **IAM policy JSON** with minimum required permissions (principle of least privilege)
3. **Bucket policy** (if needed) to ensure objects stay private
4. **Verification steps** to test that presigned URLs work correctly
5. **Security best practices** for managing AWS credentials

## Important Constraints

- ✅ Objects must be **private** (no public access)
- ✅ Use presigned URLs for both upload (PUT) and download (GET)
- ✅ Presigned URLs should expire (PUT: 10 minutes, GET: 1 hour)
- ✅ Store only S3 keys in database, not permanent URLs
- ❌ NO public-read ACL
- ❌ NO publicly readable bucket policy

Please provide:
1. Detailed step-by-step instructions
2. IAM policy JSON
3. Bucket configuration checklist
4. Test commands to verify everything works

