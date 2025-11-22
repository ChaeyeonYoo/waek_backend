# S3 Presigned URL 생성 서비스
# 클라이언트가 직접 S3에 파일을 업로드할 수 있도록 Presigned URL을 생성합니다
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

  # Presigned PUT URL 생성 (업로드용)
  # @param file_name [String] 업로드할 파일명 (예: "workout_123.jpg")
  # @param content_type [String] 파일 타입 (예: "image/jpeg")
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 1시간)
  # @return [Hash] { url: presigned_url, key: s3_key, expires_at: 만료시간 }
  def self.generate_presigned_url(file_name:, content_type:, expires_in: 3600)
    bucket = ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
    
    # S3 키 생성
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
      # acl 제거: 기본적으로 private로 업로드됨
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

  # Presigned GET URL 생성 (다운로드/조회용)
  # @param s3_key [String] S3 키
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 1시간)
  # @return [String] Presigned GET URL
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

