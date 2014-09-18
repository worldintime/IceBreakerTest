Rails.application.routes.draw do
  devise_for :users
  root 'application#home'

  namespace :api, defaults: {format: 'json'} do
    resources :users, only: [], path: '/' do
      collection do
        post :users, action: :create
        post :search, :location, :send_push_notification, :forgot_password, :edit_profile
      end
    end

    resources :sessions, only: [:create] do
      collection do
        delete :destroy
      end
    end
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
