class Api::UsersController < ApplicationController
  before_action :api_authenticate_user, except: [:create, :forgot_password, :send_push_notification]

  swagger_controller :users, "User Management"

  swagger_api :create do
    summary "Creates a new User"
    param :query, :first_name, :string, :required, "First name"
    param :query, :last_name, :string, :required, "Last name"
    param :query, :gender, :string, :required, "Gender"
    param :query, :date_of_birth, :date, :optional, "Date of birth"
    param :query, :user_name, :string, :required, "User name"
    param :query, :email, :string, :required, "Email address"
    param :query, :password, :string, :required, "Password"
    param :query, :avatar, :string, :optional, "User's avatar"
  end

  def create
    user = User.new(first_name: params[:first_name], last_name: params[:last_name], password: params[:password],
                    gender: params[:gender], date_of_birth: params[:date_of_birth], user_name: params[:user_name],
                    password_confirmation: params[:password_confirmation], email: params[:email], avatar: params[:avatar])

    if user.save
      render json: {success: true,
                       info: 'Message sent on your email, please check it',
                       data: {user: user},
                     status: 200
      }
    else
      render json: {errors: user.errors.full_messages, success: false}, status: 200
    end
  end

  swagger_api :edit_profile do
    summary "Edit profile of existing User"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, :first_name, :string, :required, "First name"
    param :query, :last_name, :string, :required, "Last name"
    param :query, :gender, :string, :required, "Gender"
    param :query, :date_of_birth, :date, :optional, "Date of birth"
    param :query, :user_name, :string, :required, "User name"
    param :query, :email, :string, :required, "Email address"
    param :query, :password, :string, :required, "Password"
    param :query, :avatar, :string, :optional, "User's avatar"
  end

  def edit_profile
    if @current_user
      @current_user.update_attributes(user_params)
      render json: {success: true,
                       info: 'Profile successfully updated.',
                     status: 200
      }
    else
      render json: {success: false,
                       info: 'Session expired. Please login.',
                     status: 200
      }
    end
  end

  swagger_api :forgot_password do
    summary "Restore forgotten password"
    param :query, :email, :string, :required, "Email address"
  end

  def forgot_password
    user = User.find_by_email(params[:email])
    if user
      password = SecureRandom.hex(8)
      user.update_attributes(password: password, password_confirmation: password)

      render json: {success: true,
                       info: 'New password was sent on your email',
                     status: 200}
    else
      render json: {success: false,
                       info: "Email doesn't exist",
                     status: 200}
    end
  end

  swagger_api :search do
    summary "Search designated Users"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end

  def search
    lat = @current_user.latitude
    lng = @current_user.longitude

    if lat.nil? || lng.nil?
      render json: { success: false,
                        info: 'Latitude or Longitude are missed',
                      status: 200 }
    end

    @designated_users = User.near([lat, lng], 0.1).where.not(id: @current_user.id)
  end

  swagger_api :set_location do
    summary "Set location of current User"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end

  def set_location
    lat = params[:location][:latitude]
    lng = params[:location][:longitude]

    if lat.nil? || lng.nil?
      render json: { success: false,
                        info: 'Latitude or Longitude are missed',
                      status: 200 }
    elsif @current_user.update_attributes(latitude: lat, longitude: lng)
      render json: { success: true,
                        info: 'New location was set successfully',
                      status: 200 }
    end
  end

  # Temporarily action (for front-end testing)
  def send_push_notification
    device = params[:device_type]
    result = false
    message = 'Hi IceBr8kr team!'
    info = 'Something went wrong'

    if device == 'IOS'
      notification = Grocer::Notification.new(
        device_token: params[:device_token],
        alert:        message
      )
      IceBr8kr::Application::IOS_PUSHER.push(notification)
      result = true
      info = 'Pushed to IOS'
    elsif device == 'Android'
      require 'rest_client'
      url = 'https://android.googleapis.com/gcm/send'
      headers = {
        'Authorization' => 'key=AIzaSyBCK9NX8gRY51g9UwtY1znEirJuZqTNmAU',
        'Content-Type' => "application/json"
      }
      request = {
        'registration_ids' => [params[:device_token]],
        data: {
          'message' => message
        }
      }

      response = RestClient.post(url, request.to_json, headers)
      response_hash = YAML.load(response)
      result = true
      info = 'Pushed to Android'
    end

    render json: { success: result.to_s, info: info }, status: 200
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up).push(:first_name, :last_name)
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :gender, :date_of_birth,
                                 :user_name, :password, :password_confirmation, :avatar)
  end

end
