require 'swagger_helper'

RSpec.describe 'Feedbacks API', type: :request do
  path '/feedbacks' do
    post '피드백 저장' do
      tags '피드백'
      description '사용자 피드백을 저장합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :feedback, in: :body, schema: {
        type: :object,
        properties: {
          feedback: {
            type: :object,
            properties: {
              content: { type: :string, description: '피드백 내용', example: '앱이 정말 좋아요! 계속 사용하고 싶습니다.' },
              app_version: { type: :string, description: '앱 버전 (선택사항)', example: '1.0.0' },
              platform: { type: :string, description: '플랫폼', example: 'ios' }
            },
            required: ['content', 'platform']
          }
        }
      }

      response '201', '피드백 생성 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            user_id: { type: :integer },
            content: { type: :string },
            app_version: { type: :string, nullable: true },
            platform: { type: :string },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:feedback) do
          {
            feedback: {
              content: '앱이 정말 좋아요! 계속 사용하고 싶습니다.',
              app_version: '1.0.0',
              platform: 'ios'
            }
          }
        end

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:Authorization) { nil }
        let(:feedback) { { feedback: {} } }

        run_test!
      end

      response '422', '유효성 검사 실패' do
        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:feedback) { { feedback: { content: '', platform: '' } } }

        run_test!
      end
    end
  end
end


