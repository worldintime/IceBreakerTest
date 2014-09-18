Rails.application.routes.draw do
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
<<<<<<< HEAD
    resources :users
    post 'custom_canned_statement', to: 'users#custom_canned_statement'
    delete 'destroy_canned_statement', to: 'users#destroy_canned_statement'
    post 'sessions', to: 'sessions#create', as: :login
    post 'destroy_sessions', to: "sessions#destroy_sessions"
    post 'search', to: 'users#search'
    post 'location', to: 'users#set_location'
    post 'send_push_notification', to: 'users#send_push_notification'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
    match 'upload_avatar', to: 'users#upload_avatar', via: [:get, :post, :options]
    post 'unread_messages', to: 'conversations#unread_messages'
    post 'history_of_digital_hello', to: 'conversations#history_of_digital_hello'
    post 'create_message', to: 'conversations#create_message'
    post 'messaging', to: 'conversations#messaging'
    post 'conversation_detail', to: 'conversations#conversation_detail'
=======
    resources :users do
      collection do 
        post 'canned_statements'
        # post 'custom_canned_statement'
        # delete 'destroy_canned_statement'
        post 'search'
        post 'set_location'
        post 'forgot_password'
        post 'edit_profile'
      end
    end

    post 'sessions', to: 'sessions#create', as: 'login'
    delete 'sessions', to: 'sessions#destroy', as: 'logout'
>>>>>>> canned_statement
  end

  # match 'upload_avatar', :controller => 'web_hits', :action => 'options', :constraints => {:method => 'OPTIONS'}

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
