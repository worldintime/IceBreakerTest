class Omniauth::SessionsController < ApplicationController


  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    if user.present?
      render json: user
    else
      render json: 'Error: Omniauth is empty'
    end
  end
end
