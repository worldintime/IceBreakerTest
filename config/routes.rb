Rails.application.routes.draw do
  root 'application#home'

  devise_for :users, controllers: {confirmations: "api/confirmations"}
  devise_scope :user do
    get '/users/confirmed', to: 'api/confirmations#confirmed'
  end

  namespace :api, defaults: {format: 'json'} do
    post 'test_push_notification', to: 'users#test_push_notification'

    resources :users
    post 'canned_statements',      to: 'users#canned_statements'
    post 'search',                 to: 'users#search'
    post 'set_location',           to: 'users#set_location'
    post 'reset_location',         to: 'users#reset_location'
    post 'send_push_notification', to: 'users#send_push_notification'
    post 'forgot_password',        to: 'users#forgot_password'
    post 'edit_profile',           to: 'users#edit_profile'
    match 'upload_avatar',         to: 'users#upload_avatar', via: [:get, :post, :options]

    post 'sessions',         to: 'sessions#create', as: 'login'
    post 'destroy_sessions', to: 'sessions#destroy', as: 'logout'

    post 'unread_messages',          to: 'conversations#unread_messages'
    post 'create_message',           to: 'conversations#create_message'
    post 'messaging',                to: 'conversations#messaging'
    post 'history_of_digital_hello', to: 'conversations#history_of_digital_hello'
    post 'conversation_detail',      to: 'conversations#conversation_detail'
  end
end
