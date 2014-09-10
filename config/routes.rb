Rails.application.routes.draw do

  devise_for :users

  namespace :api, defaults: {format: 'json'} do
    resources :users
    post 'sessions', to: 'sessions#create', as: 'login'
    delete 'sessions', to: 'sessions#destroy', as: 'logout'
    post 'sessions/reset_password', to: 'sessions#reset_password'
  end

end
