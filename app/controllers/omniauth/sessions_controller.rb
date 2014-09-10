class Omniauth::SessionsController < ApplicationController


  def create
    user = User.from_omniauth(env["omniauth.auth"])
    session[:user_id] = user.id
    omniauth = request.env['omniauth.auth']

    if omniauth
      first_name = omniauth['extra']['raw_info']['first_name']
      last_name = omniauth['extra']['raw_info']['last_name']
      email = omniauth['extra']['raw_info']['email']
      image = omniauth['info']['image']
      gender = omniauth['extra']['raw_info']['gender']
      birthday = omniauth['extra']['raw_info']['birthday']
      uid = omniauth['uid']
      render text: first_name + " - " + last_name + " - " + email + " - " + image + " - " + birthday + " - " + gender + " - " + uid
    else
      render text: 'Error: Omniauth is empty'
    end
  end
end
