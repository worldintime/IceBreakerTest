Rails.application.routes.draw do
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'search', to: 'users#search'
    post 'location', to: 'users#set_location'
    post 'send_push_notification', to: 'users#send_push_notification'

    post 'sessions', to: 'sessions#create', as: 'login'
    post 'destroy_sessions', to: "sessions#destroy_sessions", as: 'logout'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
    post 'unread_messages', to: 'conversations#unread_messages'
    post 'history_of_digital_hello', to: 'conversations#history_of_digital_hello'
    post 'messaging', to: 'conversations#messaging'
    post 'conversation_detail', to: 'conversations#conversation_detail'
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
