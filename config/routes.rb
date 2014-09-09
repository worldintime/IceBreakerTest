Rails.application.routes.draw do
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'sessions', to: 'sessions#create', as: 'login'
    delete 'sessions', to: 'sessions#destroy', as: 'logout'
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end

  get '/signout' => 'sessions#destroy', as: :signout
  get '/signin' => 'sessions#new', as: :signin
end