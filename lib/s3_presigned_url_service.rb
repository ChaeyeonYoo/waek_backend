# S3 Presigned URL 생성 서비스
# 
# 이 서비스는 iOS 앱이 직접 S3에 파일을 업로드/다운로드할 수 있도록
# Presigned URL을 생성합니다.
#
# 중요 사항:
# - 모든 S3 객체는 private로 유지됩니다 (public-read ACL 없음)
# - DB에는 S3 key(photo_key)만 저장하고, 영구적인 public URL은 저장하지 않습니다
# - 이미지 조회 시에는 presigned GET URL을 동적으로 생성합니다
# - Presigned URL은 만료 시간이 있어 일시적으로만 접근 가능합니다
#
class S3PresignedUrlService
  require 'aws-sdk-s3'
  require 'securerandom'

  # 프로덕션 환경 기본 버킷 이름
  PRODUCTION_BUCKET = 'waek-photo-bucket'
  DEFAULT_REGION = 'ap-northeast-2'

  # S3 클라이언트 초기화
  # 환경 변수에서 자격 증명을 읽어옵니다
  # @return [Aws::S3::Client] S3 클라이언트 인스턴스
  def self.s3_client
    @s3_client ||= begin
      access_key_id = ENV['AWS_ACCESS_KEY_ID']
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      region = ENV.fetch('AWS_REGION', DEFAULT_REGION)

      # 프로덕션 환경에서 자격 증명 누락 시 경고
      if Rails.env.production?
        if access_key_id.blank? || secret_access_key.blank?
          Rails.logger.error "S3 자격 증명이 설정되지 않았습니다. AWS_ACCESS_KEY_ID와 AWS_SECRET_ACCESS_KEY를 확인하세요."
          raise "AWS credentials are missing in production environment"
        end
      end

      Aws::S3::Client.new(
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        region: region
      )
    end
  end

  # Presigned PUT URL 생성 (업로드용)
  # iOS 앱이 이 URL을 사용하여 S3에 직접 이미지를 업로드합니다
  #
  # @param file_name [String] 업로드할 파일명 (예: "walk_123.jpg")
  # @param content_type [String] 파일 타입 (예: "image/jpeg", "image/png")
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 1시간)
  # @return [Hash, nil] { url: presigned_url, key: s3_key, expires_at: 만료시간, bucket: bucket } 또는 nil (실패 시)
  #
  # 반환된 s3_key는 DB의 walks.photo_key 컬럼에 저장됩니다
  def self.generate_presigned_url(file_name:, content_type:, expires_in: 3600)
    bucket = bucket_name
    
    # S3 키 생성 (workouts/ 타임스탬프_랜덤_파일명 형식)
    timestamp = Time.current.to_i
    s3_key = "workouts/#{timestamp}_#{SecureRandom.hex(8)}_#{file_name}"

    # Presigned PUT URL 생성
    # ACL을 지정하지 않으므로 객체는 기본적으로 private로 업로드됩니다
    signer = Aws::S3::Presigner.new(client: s3_client)
    url = signer.presigned_url(
      :put_object,
      bucket: bucket,
      key: s3_key,
      content_type: content_type,
      expires_in: expires_in
    )

    Rails.logger.info "S3 Presigned PUT URL 생성 성공: bucket=#{bucket}, key=#{s3_key}"

    {
      url: url,
      key: s3_key,
      expires_at: Time.current + expires_in.seconds,
      bucket: bucket
    }
  rescue Aws::Errors::ServiceError => e
    # 자격 증명이나 버킷 정보는 로그에 포함하지 않음 (보안)
    Rails.logger.error "S3 Presigned URL 생성 실패: #{e.class.name} - #{e.message}"
    nil
  rescue => e
    Rails.logger.error "S3 Presigned URL 생성 중 예상치 못한 오류: #{e.class.name} - #{e.message}"
    nil
  end

  # Presigned GET URL 생성 (다운로드/조회용)
  # DB에 저장된 photo_key를 기반으로 임시 다운로드 URL을 생성합니다
  #
  # @param s3_key [String] DB에 저장된 S3 키 (walks.photo_key)
  # @param expires_in [Integer] URL 유효 시간 (초, 기본값: 1시간)
  # @return [String, nil] Presigned GET URL 또는 nil
  #
  # 이 URL은 만료 시간이 지나면 더 이상 사용할 수 없습니다
  # iOS 앱은 이미지를 조회할 때마다 새로운 presigned URL을 받아야 합니다
  def self.presigned_get_url(s3_key, expires_in: 3600)
    return nil if s3_key.blank?
    
    bucket = bucket_name

    signer = Aws::S3::Presigner.new(client: s3_client)
    url = signer.presigned_url(
      :get_object,
      bucket: bucket,
      key: s3_key,
      expires_in: expires_in
    )

    url
  rescue Aws::Errors::ServiceError => e
    Rails.logger.error "S3 Presigned GET URL 생성 실패: #{e.class.name} - #{e.message}"
    nil
  rescue => e
    Rails.logger.error "S3 Presigned GET URL 생성 중 예상치 못한 오류: #{e.class.name} - #{e.message}"
    nil
  end

  private

  # 버킷 이름 반환
  # 환경 변수에서 읽거나, 프로덕션 환경에서는 기본값 사용
  # @return [String] S3 버킷 이름
  def self.bucket_name
    if Rails.env.production?
      ENV.fetch('AWS_S3_BUCKET', PRODUCTION_BUCKET)
    else
      ENV.fetch('AWS_S3_BUCKET', "waek-backend-#{Rails.env}")
    end
  end
end
