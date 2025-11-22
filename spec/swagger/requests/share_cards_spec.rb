require 'swagger_helper'

RSpec.describe 'Share Cards API', type: :request do
  path '/share_cards' do
    post '카드 저장' do
      tags '카드'
      description '산책 결과를 공유할 수 있는 카드를 저장합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :share_card, in: :body, schema: {
        type: :object,
        properties: {
          share_card: {
            type: :object,
            properties: {
              workout_id: { type: :integer, description: '연결된 Workout ID', example: 1 },
              card_date: { type: :string, format: :date, description: '카드에 표시되는 날짜', example: '2024-11-15' },
              frame_theme_key: { type: :string, description: '프레임/테마 키', example: 'theme_1' },
              image_url: { type: :string, description: '완성된 카드 이미지 URL', example: 'https://example.com/cards/card_123.jpg' },
              distance: { type: :number, format: :float, description: '거리 (미터)', example: 2500.5 },
              steps: { type: :integer, description: '걸음수', example: 3500 },
              duration: { type: :integer, description: '지속 시간 (초)', example: 1800 }
            },
            required: ['workout_id', 'card_date']
          }
        }
      }

      response '201', '카드 생성 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            user_id: { type: :integer },
            workout_id: { type: :integer },
            card_date: { type: :string },
            frame_theme_key: { type: :string, nullable: true },
            image_url: { type: :string, nullable: true },
            distance: { type: :string, nullable: true },
            steps: { type: :integer, nullable: true },
            duration: { type: :integer, nullable: true },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(provider: 1, provider_id: 'test_123', nickname: 'Test User') }
        let(:workout) { user.workouts.create!(workout_date: '2024-11-15', started_at: Time.current, ended_at: Time.current + 30.minutes, duration: 1800) }
        let(:token) { JwtService.encode(user.id) }
        let(:Authorization) { "Bearer #{token}" }
        let(:share_card) do
          {
            share_card: {
              workout_id: workout.id,
              card_date: '2024-11-15',
              frame_theme_key: 'theme_1',
              image_url: 'https://example.com/cards/card_123.jpg',
              distance: 2500.5,
              steps: 3500,
              duration: 1800
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
        let(:share_card) { { share_card: {} } }

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
        let(:share_card) { { share_card: { card_date: '' } } }

        run_test!
      end
    end

    get '카드 조회' do
      tags '카드'
      description '저장된 카드를 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      parameter name: :date, in: :query, type: :string, format: :date, required: false,
        description: '특정 날짜의 카드만 조회 (YYYY-MM-DD). 없으면 모든 카드 조회'

      response '200', '조회 성공' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              workout_id: { type: :integer },
              card_date: { type: :string },
              frame_theme_key: { type: :string, nullable: true },
              image_url: { type: :string, nullable: true },
              distance: { type: :string, nullable: true },
              steps: { type: :integer, nullable: true },
              duration: { type: :integer, nullable: true }
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


