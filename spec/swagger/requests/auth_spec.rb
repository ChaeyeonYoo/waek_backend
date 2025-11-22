require 'swagger_helper'

RSpec.describe 'Auth API', type: :request do
  path '/auth/social_login' do
    post '소셜 로그인' do
      tags '인증'
      description '소셜 로그인을 통해 JWT 토큰을 발급받습니다.'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :auth, in: :body, schema: {
        type: :object,
        properties: {
          provider: { type: :integer, description: '소셜 로그인 제공자: 1 (Apple), 2 (Kakao), 3 (Google)', example: 1 },
          provider_id: { type: :string, description: '소셜 로그인 제공자에서 받은 유저 고유 ID', example: 'apple_user_12345' },
          nickname: { type: :string, description: '사용자 닉네임', example: '홍길동' },
          social_email: { type: :string, description: '소셜 로그인 이메일 (선택사항)', example: 'user@example.com' },
          profile_image_key: { type: :integer, description: '프로필 이미지 키 (선택사항)', example: 1 }
        },
        required: ['provider', 'provider_id', 'nickname']
      }

      response '200', '로그인 성공' do
        schema type: :object,
          properties: {
            token: { type: :string, description: 'JWT 토큰' },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                nickname: { type: :string },
                profile_image_key: { type: :integer, nullable: true },
                provider: { type: :integer },
                is_premium: { type: :boolean }
              }
            }
          }

        let(:auth) do
          {
            provider: 1,
            provider_id: 'test_user_123',
            nickname: '테스트유저',
            social_email: 'test@example.com',
            profile_image_key: 1
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['token']).to be_present
          expect(data['user']).to be_present
        end
      end

      response '400', '필수 파라미터 누락' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:auth) { { provider: 1 } }

        run_test!
      end

      response '422', '유효성 검사 실패' do
        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } }
          }

        let(:auth) do
          {
            provider: 1,
            provider_id: 'test_user_123',
            nickname: ''
          }
        end

        run_test!
      end
    end
  end
end


