# AWS SDK 초기화 설정
# 
# 이 파일은 Rails 애플리케이션 시작 시 AWS SDK를 초기화합니다.
# 환경 변수를 통해 AWS 자격 증명을 설정합니다.
#
# 필수 환경 변수:
# - AWS_ACCESS_KEY_ID: IAM 사용자의 액세스 키 ID
# - AWS_SECRET_ACCESS_KEY: IAM 사용자의 비밀 액세스 키
# - AWS_REGION: AWS 리전 (기본값: ap-northeast-2)
# - AWS_S3_BUCKET: S3 버킷 이름 (프로덕션 기본값: waek-photo-bucket)
#
# 보안 주의사항:
# - 환경 변수는 절대 Git에 커밋하지 마세요
# - .env 파일은 .gitignore에 포함되어 있습니다
# - 프로덕션 서버에서는 시스템 환경 변수나 안전한 secrets 관리 도구를 사용하세요

require 'aws-sdk-s3'

# AWS SDK 전역 설정
# 환경 변수가 설정된 경우에만 자격 증명 설정
if ENV['AWS_ACCESS_KEY_ID'].present? && ENV['AWS_SECRET_ACCESS_KEY'].present?
  Aws.config.update(
    region: ENV.fetch('AWS_REGION', 'ap-northeast-2'),
    credentials: Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY']
    )
  )
else
  # 환경 변수가 없으면 기본 설정만 (자격 증명은 나중에 설정 가능)
  Aws.config.update(
    region: ENV.fetch('AWS_REGION', 'ap-northeast-2')
  )
end

Rails.application.configure do
  # 프로덕션 환경에서 AWS 자격 증명 확인
  if Rails.env.production?
    required_vars = %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      Rails.logger.warn "⚠️  AWS 환경 변수가 설정되지 않았습니다: #{missing_vars.join(', ')}"
      Rails.logger.warn "S3 Presigned URL 기능이 작동하지 않을 수 있습니다."
    else
      Rails.logger.info "✅ AWS 자격 증명이 설정되었습니다."
      Rails.logger.info "   Region: #{ENV.fetch('AWS_REGION', 'ap-northeast-2')}"
      Rails.logger.info "   Bucket: #{ENV.fetch('AWS_S3_BUCKET', 'waek-photo-bucket')}"
    end
  end
end

# AWS SDK 로깅 설정 (개발 환경에서만)
if Rails.env.development?
  Aws.config.update(
    logger: Rails.logger,
    log_level: :info
  )
end
