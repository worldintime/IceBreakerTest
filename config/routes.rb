Rails.application.routes.draw do
  devise_for :users
  root 'application#home'

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'search', to: 'users#search'
    post 'location', to: 'users#set_location'
    post 'send_push_notification', to: 'users#send_push_notification'

    post 'sessions', to: 'sessions#create', as: 'login'
    post 'destroy_sessions', to: 'sessions#destroy', as: 'logout'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
    match 'upload_avatar', to: 'users#upload_avatar', via: [:get, :post, :options]
    post 'unread_messages', to: 'conversations#unread_messages'
    post 'create_message', to: 'conversations#create_message'
    post 'messaging', to: 'conversations#messaging'
  end

  # match 'upload_avatar', :controller => 'web_hits', :action => 'options', :constraints => {:method => 'OPTIONS'}

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
