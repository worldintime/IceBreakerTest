class Api::SessionsController < ApplicationController
  swagger_controller :users, "Session Management"

  def create
    user = User.find_for_authentication(email: params[:email])
    if user
      if user.valid_password?(params[:password]) && user.confirmed_at != nil
        session = create_session user, params[:auth]
        render json: { success: true,
                          info: 'Logged in',
                          data: {authentication_token: session[:auth_token], user: user, avatar: user.avatar.url},
                        status: 200
                     }
      elsif user.confirmed_at == nil
         render json: { errors: 'Please confirm your email first'}, status: 200
      else
        render json: { errors: 'Email or password is incorrect!' } , status: 200
      end
    else
      render json: {errors: 'User not found!'}, status: 200
    end
  end

  swagger_api :create do
    summary "Login User"
    param :query, :email, :string, :required, "Email address"
    param :query, :password, :string, :required, "Password"
  end

  def destroy_sessions
    session = Session.where(auth_token: params[:authentication_token]).first
    if session
      destroy_session session
      render json: { success: true, info: 'Logged out', status: 200 }
    else
      render json: { success: false, info: 'Not found', status: 200 }
    end
  end

  swagger_api :destroy_sessions do
    summary "Logout current User"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end

  def reset_password
    @user = User.find_by_email(params[:email])
    if @user.present?
      @user.send_reset_password_instructions
      render json: { message: 'Confirmation instructions sent. Please check your email.' }
    else
      render json: { message: 'No such email' }
    end
  end

  swagger_api :reset_password do
    summary "Reset forgotten password"
    param :query, :email, :string, :required, "Email address"
  end

  private

  def create_session user, auth
    range = [*'0'..'9', *'a'..'z', *'A'..'Z']
    session = {user_id: user.id, auth_token: Array.new(30){range.sample}.join, updated_at: Time.now}
    if auth.present?
      if auth[:device].present? && auth[:device_token].present?
        session[:device] = auth['device']
        session[:device_token] = auth['device_token']
      end
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
    params.require(:session).permit(:auth_token, :device, :device_token, :updated_at, :email, :password,
                                    :user_id)
  end

end
