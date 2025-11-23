require 'swagger_helper'

RSpec.describe 'Walks API', type: :request do
  path '/uploads/presigned_url' do
    post 'Presigned URL 발급' do
      tags '산책 기록'
      description '산책 사진 업로드용 S3 presigned URL을 발급합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          content_type: { type: :string, example: 'image/png', description: 'image/jpeg, image/png 등' },
          use_case: { type: :string, example: 'walk_card', description: '선택사항' }
        }
      }

      response '200', 'Presigned URL 발급 성공' do
        schema type: :object,
          properties: {
            upload_url: { type: :string, description: 'S3 업로드용 presigned URL' },
            photo_key: { type: :string, description: 'DB에 저장할 S3 key' },
            expires_in: { type: :integer, example: 600, description: '유효 시간 (초)' }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:body) { { content_type: 'image/png' } }

        before { user }
        run_test!
      end

      response '401', '인증 실패' do
        let(:Authorization) { nil }
        let(:body) { { content_type: 'image/png' } }
        run_test!
      end
    end
  end

  path '/walks' do
    post '산책 기록 생성' do
      tags '산책 기록'
      description '새로운 산책 기록을 생성합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :walk, in: :body, schema: {
        type: :object,
        properties: {
          walk: {
            type: :object,
            properties: {
              distance_meters: { type: :integer, example: 2700 },
              step_count: { type: :integer, example: 2380 },
              duration_seconds: { type: :integer, example: 1800 },
              started_at: { type: :string, format: 'date-time', example: '2025-07-12T01:30:00Z' },
              ended_at: { type: :string, format: 'date-time', example: '2025-07-12T02:00:00Z' },
              photo_key: { type: :string, example: 'walks/user_1/2025/07/12/uuid.png' }
            },
            required: ['started_at', 'ended_at', 'duration_seconds']
          }
        }
      }

      response '201', '산책 기록 생성 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            distance_meters: { type: :integer },
            step_count: { type: :integer },
            duration_seconds: { type: :integer },
            started_at: { type: :string },
            ended_at: { type: :string },
            photo: {
              type: :object,
              properties: {
                key: { type: :string },
                url: { type: :string, description: 'Presigned GET URL' }
              }
            },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:walk) do
          {
            walk: {
              distance_meters: 2700,
              step_count: 2380,
              duration_seconds: 1800,
              started_at: '2025-07-12T01:30:00Z',
              ended_at: '2025-07-12T02:00:00Z'
            }
          }
        end

        before { user }
        run_test!
      end

      response '400', '필수 필드 누락' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:walk) { { walk: {} } }

        before { user }
        run_test!
      end
    end

    get '산책 기록 목록 조회' do
      tags '산책 기록'
      description '산책 기록 목록을 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false, example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, example: 20

      response '200', '조회 성공' do
        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  date: { type: :string },
                  distance_meters: { type: :integer },
                  step_count: { type: :integer },
                  duration_seconds: { type: :integer },
                  photo: {
                    type: :object,
                    properties: {
                      key: { type: :string },
                      url: { type: :string }
                    }
                  },
                  created_at: { type: :string },
                  updated_at: { type: :string }
                }
              }
            },
            page: { type: :integer },
            per_page: { type: :integer },
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

  path '/walks/{id}' do
    get '산책 기록 상세 조회' do
      tags '산책 기록'
      description '특정 산책 기록의 상세 정보를 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      parameter name: :id, in: :path, type: :integer, required: true, example: 1

      response '200', '조회 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            distance_meters: { type: :integer },
            step_count: { type: :integer },
            duration_seconds: { type: :integer },
            started_at: { type: :string },
            ended_at: { type: :string },
            photo: {
              type: :object,
              properties: {
                key: { type: :string },
                url: { type: :string }
              }
            },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:walk) { user.walks.create!(started_at: Time.current, ended_at: Time.current + 30.minutes, duration_seconds: 1800, status: 'active') }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:id) { walk.id }

        before { user; walk }
        run_test!
      end

      response '404', '기록을 찾을 수 없음' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:id) { 99999 }

        before { user }
        run_test!
      end
    end

    delete '산책 기록 삭제' do
      tags '산책 기록'
      description '산책 기록을 soft delete 처리합니다.'
      security [bearerAuth: []]

      parameter name: :id, in: :path, type: :integer, required: true, example: 1

      response '204', '삭제 성공' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:walk) { user.walks.create!(started_at: Time.current, ended_at: Time.current + 30.minutes, duration_seconds: 1800, status: 'active') }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:id) { walk.id }

        before { user; walk }
        run_test!
      end
    end
  end
end

