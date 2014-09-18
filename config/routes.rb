Rails.application.routes.draw do
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
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
  end

  scope module: 'omniauth' do
    get '/auth/:provider/callback' => 'sessions#create'
  end
end
