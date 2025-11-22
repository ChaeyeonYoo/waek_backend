require 'swagger_helper'

RSpec.describe 'Daily Workouts API', type: :request do
  path '/daily_workouts/{date}' do
    get '특정 날짜의 일일 요약 조회' do
      tags '일일 요약'
      description '특정 날짜의 일일 요약 정보를 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      parameter name: :date, in: :path, type: :string, format: :date, required: true,
        description: '조회할 날짜 (YYYY-MM-DD)', example: '2024-11-15'

      response '200', '조회 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer, nullable: true },
            user_id: { type: :integer },
            date: { type: :string },
            is_workout_goal_achieved: { type: :boolean },
            has_walk_10min: { type: :boolean },
            created_at: { type: :string, nullable: true },
            updated_at: { type: :string, nullable: true }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:date) { '2024-11-15' }

        run_test!
      end

      response '400', '날짜 파라미터 누락' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:date) { '' }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:Authorization) { nil }
        let(:date) { '2024-11-15' }

        run_test!
      end
    end
  end

  path '/daily_workouts' do
    get '일일 요약 목록 조회' do
      tags '일일 요약'
      description '날짜 범위의 일일 요약 목록을 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false,
        description: '시작 날짜 (YYYY-MM-DD)'
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false,
        description: '종료 날짜 (YYYY-MM-DD)'

      response '200', '조회 성공' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              date: { type: :string },
              is_workout_goal_achieved: { type: :boolean },
              has_walk_10min: { type: :boolean }
            }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:start_date) { nil }
        let(:end_date) { nil }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        let(:Authorization) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }

        run_test!
      end
    end
  end
end


