Rails.application.routes.draw do
  devise_for :users
  root 'application#home'

  namespace :api, defaults: {format: 'json'} do

    post 'sessions', to: 'sessions#create', as: 'login'
    post 'destroy_sessions', to: 'sessions#destroy_sessions', as: 'logout'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
    post 'unread_messages', to: 'conversations#unread_messages'
    post 'history_of_digital_hello', to: 'conversations#history_of_digital_hello'
    post 'messaging', to: 'conversations#messaging'
    post 'conversation_detail', to: 'conversations#conversation_detail'

    resources :users do
      collection do
        post 'canned_statements'
        post 'search'
        post 'location'
        post 'forgot_password'
        post 'edit_profile'
        post 'send_push_notification'
        post 'forgot_password'
        post 'edit_profile'
        match 'upload_avatar', via: [:get, :post, :options]
      end
    end
  end
end
