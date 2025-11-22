Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # 인증 관련 API
  post 'auth/social_login', to: 'auth#social_login'  # POST /auth/social_login

  # 산책 기록 API
  resources :workouts, only: [:create, :index]  # POST /workouts, GET /workouts

  # 일일 요약 API
  get 'daily_workouts/:date', to: 'daily_workouts#show', as: 'daily_workout'  # GET /daily_workouts/2024-11-15
  get 'daily_workouts', to: 'daily_workouts#index'  # GET /daily_workouts

  # 카드 API
  resources :share_cards, only: [:create, :index]  # POST /share_cards, GET /share_cards

  # 피드백 API
  resources :feedbacks, only: [:create]  # POST /feedbacks
end
