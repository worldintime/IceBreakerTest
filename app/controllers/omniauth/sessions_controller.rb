class Omniauth::SessionsController < ApplicationController

    def create
      puts '+++++++++++++++++++++++++++++ENTER'
      user = User.from_omniauth(env["omniauth.auth"])
      session[:user_id] = user.id
      pust session[:user_id] + '+++++++++++++++++++++++++'
      render text: "#{session[:user_id]}".html_safe
    end

    def destroy
  		reset_session
  		redirect_to root_url, notice => 'Signed out'
	  end
end
