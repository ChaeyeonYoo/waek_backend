require 'swagger_helper'

RSpec.describe 'Feedbacks API', type: :request do
  path '/feedbacks' do
    post '피드백 작성' do
      tags '피드백'
      description '피드백을 작성합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string, example: '왹왹이 너무 귀여워요! 산책할 때 동기부여 돼요 🐣', description: '피드백 내용' },
          device_type: { type: :string, enum: ['ios', 'android', 'web'], example: 'ios', description: '디바이스 타입' },
          app_version: { type: :string, example: '1.0.3', description: '앱 버전' }
        },
        required: ['content', 'device_type', 'app_version']
      }

      response '201', '피드백 작성 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            content: { type: :string },
            created_at: { type: :string }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:body) do
          {
            content: '왹왹이 너무 귀여워요!',
            device_type: 'ios',
            app_version: '1.0.3'
          }
        end

        before { user }
        run_test!
      end

      response '400', '필수 필드 누락' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:body) { { content: '테스트' } }

        before { user }
        run_test!
      end
    end
  end

  path '/admin/feedbacks' do
    get '피드백 목록 조회 (관리자용)' do
      tags '피드백'
      description '모든 피드백을 조회합니다. (관리자용)'
      security [bearerAuth: []]
      produces 'application/json'

      response '200', '조회 성공' do
        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  user: {
                    type: :object,
                    properties: {
                      id: { type: :integer },
                      username: { type: :string },
                      nickname: { type: :string }
                    }
                  },
                  content: { type: :string },
                  created_at: { type: :string }
                }
              }
            },
            total_count: { type: :integer }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end
  end
end
