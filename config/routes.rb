Rails.application.routes.draw do
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'sessions', to: 'sessions#create', as: 'login'
    post 'logout', to: 'sessions#destroy', as: 'logout'
    post 'forgot_password', to: 'users#forgot_password'
    post 'edit_profile', to: 'users#edit_profile'
    post 'upload_avatar', to: 'users#upload_avatar'
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end

  get '/signout' => 'sessions#destroy', as: :signout
  get '/signin' => 'sessions#new', as: :signin
end
