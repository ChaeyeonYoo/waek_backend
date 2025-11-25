require 'swagger_helper'

RSpec.describe 'Subscriptions API', type: :request do
  path '/me/subscription' do
    get '구독 상태 조회' do
      tags '구독'
      description '현재 사용자의 구독 상태를 조회합니다.'
      security [bearerAuth: []]
      produces 'application/json'

      response '200', '조회 성공' do
        schema type: :object,
          properties: {
            type: { type: :string, enum: ['paid', 'trial', 'none'], example: 'none', description: '구독 타입: paid(유료), trial(무료체험), none(비구독)' },
            is_subscribed: { type: :boolean },
            is_trial: { type: :boolean },
            is_expired: { type: :boolean },
            has_used_trial: { type: :boolean },
            subscription_expires_at: { type: :string, nullable: true },
            trial_expires_at: { type: :string, nullable: true },
            days_left: { type: :integer }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end

    post '구독 활성화' do
      tags '구독'
      description 'iOS 결제 후 구독을 활성화합니다.'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          platform: { type: :string, example: 'ios' },
          transaction_id: { type: :string, example: '1000000899921234' },
          expires_at: { type: :string, format: 'date-time', example: '2025-08-01T10:00:00Z' },
          auto_renew: { type: :boolean, example: true }
        },
        required: ['platform', 'transaction_id', 'expires_at']
      }

      response '200', '구독 활성화 성공' do
        schema type: :object,
          properties: {
            status: { type: :string, enum: ['subscribed'], example: 'subscribed', description: '구독 활성화 상태' },
            subscription_expires_at: { type: :string }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }
        let(:body) do
          {
            platform: 'ios',
            transaction_id: '1000000899921234',
            expires_at: (Time.current + 30.days).iso8601,
            auto_renew: true
          }
        end

        before { user }
        run_test!
      end
    end

    delete '구독 해지' do
      tags '구독'
      description '구독을 해지합니다.'
      security [bearerAuth: []]

      response '200', '구독 해지 성공' do
        schema type: :object,
          properties: {
            status: { type: :string, enum: ['cancelled'], example: 'cancelled', description: '구독 해지 상태' },
            expires_at: { type: :string }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1, is_subscribed: true, subscription_expires_at: Time.current + 30.days) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end
  end

  path '/me/subscription/temp' do
    post '임시 구독 활성화 (iOS 테스트용)' do
      tags '구독'
      description '⚠️ iOS 테스트용 임시 API입니다. 요청 바디 없이 호출하면 구독 상태가 즉시 활성화됩니다. 실 결제 도입 시 제거 예정입니다.'
      security [bearerAuth: []]
      produces 'application/json'

      response '200', '임시 구독 활성화 성공' do
        schema type: :object,
          properties: {
            status: { type: :string, enum: ['activated'], example: 'activated' },
            message: { type: :string, example: '임시 구독이 활성화되었습니다 (iOS 테스트용)' },
            is_subscribed: { type: :boolean },
            subscription_expires_at: { type: :string },
            days_left: { type: :integer }
          }

        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end
  end

  path '/me/subscription/trial' do
    post '무료체험 시작' do
      tags '구독'
      description '무료체험을 시작합니다. (1회 한정)'
      security [bearerAuth: []]

      response '204', '무료체험 시작 성공' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1, has_used_trial: false) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end

      response '400', '이미 무료체험 사용함' do
        let(:user) { User.create!(provider: 'kakao', provider_id: 'test_123', username: 'test_user', nickname: '테스트', token_version: 1, has_used_trial: true) }
        let(:token) { JwtService.encode(user.id, token_version: user.token_version) }
        let(:Authorization) { "Bearer #{token}" }

        before { user }
        run_test!
      end
    end
  end
end

