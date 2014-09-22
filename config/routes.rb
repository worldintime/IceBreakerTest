Rails.application.routes.draw do
  root 'application#home'

  devise_for :users, controllers: {confirmations: "api/confirmations"}
  devise_scope :user do
    get '/users/confirmed', to: 'api/confirmations#confirmed'
  end

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'canned_statements', to: 'users#canned_statements'
    post 'search', to: 'users#search'
    post 'location', to: 'users#location'
    post 'send_push_notification', to: 'users#send_push_notification'

    post 'sessions', to: 'sessions#create', as: 'login'
    post 'destroy_sessions', to: 'sessions#destroy', as: 'logout'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
    match 'upload_avatar', to: 'users#upload_avatar', via: [:get, :post, :options]
    post 'unread_messages', to: 'conversations#unread_messages'
    post 'create_message', to: 'conversations#create_message'
    post 'messaging', to: 'conversations#messaging'
    post 'history_of_digital_hello', to: 'conversations#history_of_digital_hello'
    post 'conversation_detail', to: 'conversations#conversation_detail'
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
