class Api::UsersController < ApplicationController
  before_action :api_authenticate_user, except: [:create, :forgot_password]

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
