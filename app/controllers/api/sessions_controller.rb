class Api::SessionsController < ApplicationController


  def create
    user = User.find_for_authentication(email: params[:email])
    puts user.inspect
    puts user.valid_password?(params[:password])
    if user && user.valid_password?(params[:password])
      session = create_session user
      render json: {success: true,
                       info: 'Logged in',
                       data: {authentication_token: session[:auth_token], email: user.email},
                       status: 200
      }
    else
      render json: user.errors.full_messages, status: 401
    end
  end

  def destroy
    session = Session.where(auth_token: params[:authentication_token]).first
    if session
      destroy_session session
      render json: { success: true, info: 'Logged out', status: 200 }
    else
      render json: user.errors.full_messages, status: 401
    end
  end

  private

  def create_session user
    range = [*'0'..'9', *'a'..'z', *'A'..'Z']
    session = {user_id: user.id, auth_token: Array.new(30){range.sample}.join, updated_at: Time.now}
    if params[:device].present? && params[:device_token].present?
      session[:device] = params[:device]
      session[:device_token] = params[:device_token]
    end
    new_session = Session.create(session)
    session
  end

  def destroy_session session
    session.destroy
  end

  def set_session
    @session = Session.find(params[:auth_token])
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:create).push(:auth_token, :user_id)
  end

  def session_params
    params.require(:session).permit(:auth_token, :device, :device_token, :user_id, :updated_at, :email, :password,
                                    :user_id)
  end

end
