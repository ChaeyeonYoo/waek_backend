require 'swagger_helper'

RSpec.describe 'Workouts API', type: :request do
  path '/workouts' do
    post '산책 기록 저장' do
      tags '산책 기록'
      description '새로운 산책 세션을 저장합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :workout, in: :body, schema: {
        type: :object,
        properties: {
          workout: {
            type: :object,
            properties: {
              workout_date: { type: :string, format: :date, example: '2024-11-15' },
              started_at: { type: :string, format: 'date-time', example: '2024-11-15T10:00:00Z' },
              ended_at: { type: :string, format: 'date-time', example: '2024-11-15T10:30:00Z' },
              distance: { type: :number, format: :float, description: '거리 (미터)', example: 2500.5 },
              steps: { type: :integer, description: '걸음수', example: 3500 },
              duration: { type: :integer, description: '지속 시간 (초)', example: 1800 },
              calories: { type: :number, format: :float, description: '소모 칼로리', example: 120.5 }
            },
            required: ['workout_date', 'started_at', 'ended_at', 'duration']
          }
        }
      }

      response '201', '산책 기록 생성 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            user_id: { type: :integer },
            workout_date: { type: :string },
            started_at: { type: :string },
            ended_at: { type: :string },
            distance: { type: :string, nullable: true },
            steps: { type: :integer, nullable: true },
            duration: { type: :integer },
            calories: { type: :string, nullable: true },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:workout) do
          {
            workout: {
              workout_date: '2024-11-15',
              started_at: '2024-11-15T10:00:00Z',
              ended_at: '2024-11-15T10:30:00Z',
              distance: 2500.5,
              steps: 3500,
              duration: 1800,
              calories: 120.5
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
        let(:workout) { { workout: {} } }

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
        let(:workout) { { workout: { workout_date: '' } } }

        run_test!
      end
    end

    get '산책 기록 조회' do
      tags '산책 기록'
      description '저장된 산책 기록을 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      parameter name: :date, in: :query, type: :string, format: :date, required: false,
        description: '특정 날짜의 기록만 조회 (YYYY-MM-DD). 없으면 모든 기록 조회'

      response '200', '조회 성공' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              workout_date: { type: :string },
              started_at: { type: :string },
              ended_at: { type: :string },
              distance: { type: :string, nullable: true },
              steps: { type: :integer, nullable: true },
              duration: { type: :integer },
              calories: { type: :string, nullable: true }
            }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:date) { nil }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:Authorization) { nil }
        let(:date) { nil }

        run_test!
      end
    end
  end
end


