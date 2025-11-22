# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# iOS 앱에서 API를 호출할 수 있도록 CORS 설정
# 모든 origin을 허용 (개발 환경용, 프로덕션에서는 특정 도메인만 허용하도록 수정 필요)
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"  # 개발 환경에서는 모든 origin 허용 (프로덕션에서는 iOS 앱 번들 ID나 도메인으로 제한)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"]  # Authorization 헤더를 클라이언트에서 읽을 수 있도록
  end
end
