Rails.application.routes.draw do
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'search', to: 'users#search'
    post 'location', to: 'users#set_location'
    post 'send_push_notification', to: 'users#send_push_notification'

    post 'sessions', to: 'sessions#create', as: 'login'
    delete 'sessions', to: 'sessions#destroy', as: 'logout'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
