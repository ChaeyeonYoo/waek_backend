Rails.application.routes.draw do
  # Swagger UI / API (모든 환경에서 사용 가능)
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  get "up" => "rails/health#show", as: :rails_health_check

  # 인증 관련 API
  post 'auth/social/verify', to: 'auth#social_verify'
  post 'auth/social/signup', to: 'auth#social_signup'
  get 'users/check_id', to: 'auth#check_id'
  get 'me', to: 'auth#me'
  post 'auth/logout', to: 'auth#logout'
  delete 'me', to: 'auth#delete_me'

  # Walk (산책 기록) API
  post 'uploads/presigned_url', to: 'walks#presigned_url'
  resources :walks, only: [:create, :index, :show, :destroy]

  # Feedback API
  resources :feedbacks, only: [:create]
  get 'admin/feedbacks', to: 'feedbacks#admin_index'

  # Subscription (구독) API
  get 'me/subscription', to: 'subscriptions#show'
  post 'me/subscription/trial', to: 'subscriptions#start_trial'
  post 'me/subscription/temp', to: 'subscriptions#activate_temp_subscription' # 임시 구독 활성화 (iOS 테스트용)
  post 'me/subscription', to: 'subscriptions#create'
  delete 'me/subscription', to: 'subscriptions#destroy'
end
