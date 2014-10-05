class Api::UsersController < ApplicationController
  before_action :api_authenticate_user, except: [:create, :forgot_password]

  swagger_controller :users, "User Management"

  # :nocov:
  swagger_api :create do
    summary "Creates a new User"
    param :query, :first_name, :string, :required, "First name"
    param :query, :last_name, :string, :required, "Last name"
    param :query, :gender, :string, :required, "Gender"
    param :query, :date_of_birth, :date, :optional, "Date of birth"
    param :query, :user_name, :string, :required, "User name"
    param :query, :email, :string, :required, "Email address"
    param :query, :password, :string, :required, "Password"
    param :query, :password_confirmation, :string, :required, "Confirmation Password"
    param :query, :avatar, :string, :optional, "User's avatar"
    param :query, :facebook_avatar, :string, :optional, "Facebook avatar"
    param :query, :facebook_uid, :string, :optional, "Facebook user id"
  end
  # :nocov:

  def create
    user_info = {}
    fb_user_id       = params[:facebook_uid]
    existing_fb_user = fb_user_id ? User.find_by_facebook_uid(fb_user_id) : false
    icebr8kr_user    = User.find_by_email(params[:email]) if fb_user_id && !existing_fb_user

    if existing_fb_user
      @user = existing_fb_user
      user_info['existing_fb_user'] = true
    elsif icebr8kr_user
      @user = icebr8kr_user
      user_info['icebr8kr_user'] = true
      @user.update_attributes(facebook_uid: fb_user_id,
                           facebook_avatar: params[:facebook_avatar])
    else
      @user = User.new do |u|
        u.first_name            = params[:first_name]
        u.last_name             = params[:last_name]
        u.password              = params[:password]
        u.password_confirmation = params[:password_confirmation]
        u.gender                = params[:gender]
        u.date_of_birth         = params[:date_of_birth]
        u.user_name             = params[:user_name]
        u.email                 = params[:email]
        u.avatar                = params[:avatar]
        u.facebook_uid          = params[:facebook_uid]
        u.facebook_avatar       = params[:facebook_avatar]
      end
      user_info['new_fb_user'] = fb_user_id.present?
    end

    user_info.merge! params
    render json: @user.register_or_login(user_info)
  end

  # :nocov:
  swagger_api :canned_statements do
    summary "Return all canned statements"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end
  # :nocov:

  def canned_statements
    @canned_statements = CannedStatement.all
  end

  # :nocov:
  swagger_api :upload_avatar do
    summary "Upload user's avatar"
    param :query, :avatar, :string, :optional, "User's avatar"
    param :query, :email, :string, :required, "User's email"
  end
  # :nocov:

  def upload_avatar
    user = User.find_by_email(params[:email])
    if user.update_attribute(:avatar, params[:avatar])
      render json: { success: true,
                     info: 'Image successfully uploaded.',
                     data: @current_user.avatar.url(:thumb),
                     status: 200 }
    else
      render json: { success: false,
                     info: 'Failed to upload image.',
                     status: 200 }
    end
  end

  # :nocov:
  swagger_api :edit_profile do
    summary "Edit profile of existing User"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, 'user[first_name]', :string, :required, "First name"
    param :query, 'user[last_name]', :string, :required, "Last name"
    param :query, 'user[gender]', :string, :required, "Gender"
    param :query, 'user[date_of_birth]', :date, :optional, "Date of birth"
    param :query, 'user[user_name]', :string, :required, "User name"
    param :query, 'user[email]', :string, :required, "Email address"
    param :query, 'user[password]', :string, :optional, "Password"
    param :query, 'user[avatar]', :string, :optional, "User's avatar"
  end
  # :nocov:

  def edit_profile
    if @current_user.update_attributes!(user_params)
      render json: { success: true,
                     info: 'Profile successfully updated.',
                     user: @current_user,
                     avatar: @current_user.avatar.url,
                     status: 200 }
    else
      render json: { success: false,
                     info: 'Session expired. Please login.',
                     status: 200 }
    end
  end

  # :nocov:
  swagger_api :forgot_password do
    summary "Search designated Users"
    param :query, :email, :string, :required, "Email"
  end
  # :nocov:

  def forgot_password
    @user = User.find_by_email(params[:email])
    if @user
      @user.send_forgot_password_email!
      render json: { success: true,
                     info: 'New password was sent on your email',
                     status: 200 }
    else
      render json: { success: false,
                     info: "Email doesn't exist",
                     status: 200 }
    end
  end

  # :nocov:
  swagger_api :search do
    summary "Search designated Users"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end
  # :nocov:

  def search
    lat = @current_user.latitude
    lng = @current_user.longitude

    if lat.nil? || lng.nil?
      render json: { success: false,
                     info: 'Latitude or Longitude are missed',
                     status: 200 }
    end

    @users_in_radius     = User.near([lat, lng], 0.1).where.not(id: @current_user.id)
    @users_out_of_radius = User.near([lat, lng], 8).where.not(id: [@current_user.id] + @users_in_radius)
  end

  # :nocov:
  swagger_api :set_location do
    summary "Set location of current User"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, 'location[latitude]', :string, :required, "Latitude"
    param :query, 'location[longitude]', :string, :required, "Longitude"
  end
  # :nocov:

  def set_location
    render json: @current_user.set_location(params[:location][:latitude], params[:location][:longitude])
  end

  # :nocov:
  swagger_api :reset_location do
    summary "Reset location of current User"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end
  # :nocov:

  def reset_location
    render json: @current_user.reset_location!
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
