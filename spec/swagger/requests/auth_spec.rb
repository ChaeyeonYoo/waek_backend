require 'swagger_helper'

RSpec.describe 'Auth API', type: :request do
  path '/auth/social/verify' do
    post '소셜 유저 존재 확인 + 로그인' do
      tags '인증'
      description '소셜 계정으로 가입한 적이 있는지 확인하고, 있으면 로그인합니다.'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          provider: { type: :string, enum: ['kakao', 'google', 'apple'], example: 'kakao' },
          provider_id: { type: :string, example: '123456' }
        },
        required: ['provider', 'provider_id']
      }

      response '200', '기존 유저인 경우 (로그인 성공)' do
        schema type: :object,
          properties: {
            status: { type: :string, example: 'EXISTS' },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                username: { type: :string },
                nickname: { type: :string },
                profile_image_code: { type: :integer },
                provider: { type: :string }
              }
            },
            token: {
              type: :object,
              properties: {
                access_token: { type: :string },
                token_type: { type: :string, example: 'Bearer' },
                expires_in: { type: :integer, example: 3600 }
              }
            }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: '123456', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:body) { { provider: 'kakao', provider_id: '123456' } }

        before do
          user
        end

        run_test!
      end

      response '200', '기존 유저가 아닌 경우 (회원가입 필요)' do
        schema type: :object,
          properties: {
            status: { type: :string, example: 'NEED_SIGNUP' },
            provider: { type: :string }
          }

        let(:body) { { provider: 'kakao', provider_id: 'new_user_123' } }

        run_test!
      end

      response '400', '필수 필드 누락' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:body) { { provider: 'kakao' } }

        run_test!
      end
    end
  end

  path '/auth/social/signup' do
    post '회원가입' do
      tags '인증'
      description '최초 회원가입을 진행합니다.'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          provider: { type: :string, enum: ['kakao', 'google', 'apple'], example: 'kakao' },
          provider_id: { type: :string, example: '123456' },
          username: { type: :string, example: 'waek_chae' },
          nickname: { type: :string, example: '채연' },
          profile_image_code: { type: :integer, example: 2, description: '0~4 사이의 값' },
          social_email: { type: :string, example: 'test@example.com', description: '선택사항' }
        },
        required: ['provider', 'provider_id', 'username', 'nickname']
      }

      response '201', '회원가입 성공' do
        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                username: { type: :string },
                nickname: { type: :string },
                profile_image_code: { type: :integer },
                provider: { type: :string },
                created_at: { type: :string },
                updated_at: { type: :string }
              }
            },
            token: {
              type: :object,
              properties: {
                access_token: { type: :string },
                token_type: { type: :string, example: 'Bearer' },
                expires_in: { type: :integer, example: 3600 }
              }
            }
          }

        let(:body) do
          {
            provider: 'kakao',
            provider_id: "signup_#{SecureRandom.hex(8)}",
            username: "test_#{SecureRandom.hex(4)}",
            nickname: '테스트',
            profile_image_code: 2
          }
        end

        run_test!
      end

      response '400', '필수 필드 누락' do
        let(:body) { { provider: 'kakao' } }
        run_test!
      end

      response '409', 'username 중복' do
        let(:existing_user) { User.create!(provider: 'kakao', provider_id: 'existing_123', username: 'duplicate', nickname: '테스트', token_version: 1) }
        let(:body) { { provider: 'google', provider_id: 'new_123', username: 'duplicate', nickname: '테스트' } }

        before { existing_user }
        run_test!
      end
    end
  end

  path '/users/check_id' do
    get 'username 중복 확인' do
      tags '인증'
      description 'username이 사용 가능한지 확인합니다.'
      produces 'application/json'

      parameter name: :username, in: :query, type: :string, required: true, example: 'waek_chae'

      response '200', '사용 가능' do
        schema type: :object,
          properties: {
            username: { type: :string },
            available: { type: :boolean, example: true }
          }

        let(:username) { "available_#{SecureRandom.hex(4)}" }
        run_test!
      end

      response '200', '사용 불가능 (중복)' do
        schema type: :object,
          properties: {
            username: { type: :string },
            available: { type: :boolean, example: false }
          }

        let(:existing_user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'taken_username', nickname: '테스트', token_version: 1) }
        let(:username) { 'taken_username' }

        before { existing_user }
        run_test!
      end
    end
  end

  path '/me' do
    get '내 정보 조회' do
      tags '인증'
      description '현재 로그인한 사용자의 정보를 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      response '200', '조회 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            username: { type: :string },
            nickname: { type: :string },
            profile_image_code: { type: :integer },
            provider: { type: :string },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end

      response '401', '인증 실패' do
        let(:Authorization) { nil }
        run_test!
      end
    end

    delete '계정 삭제' do
      tags '인증'
      description '계정을 soft delete 처리합니다.'
      security [bearerAuth: []]

      response '204', '삭제 성공' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end
  end

  path '/auth/logout' do
    post '로그아웃' do
      tags '인증'
      description '로그아웃합니다. (token_version +1)'
      security [bearerAuth: []]

      response '204', '로그아웃 성공' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end
  end
end
