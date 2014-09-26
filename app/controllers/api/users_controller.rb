class Api::UsersController < ApplicationController
  before_action :api_authenticate_user, except: [:create, :forgot_password]

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
    param :query, :password_confirmation, :string, :required, "Confirmation Password"
    param :query, :avatar, :string, :optional, "User's avatar"
    param :query, :facebook_avatar, :string, :optional, "Facebook avatar"
    param :query, :facebook_uid, :string, :optional, "Facebook user id"
  end

  def create
    fb_user_id = params[:facebook_uid]
    existing_fb_user = fb_user_id ? User.find_by_facebook_uid(fb_user_id) : false
    if !existing_fb_user && fb_user_id # new facebook user
      password = SecureRandom.hex(8)

      # Check if facebook email is your application email
      if icebr8kr_user = User.find_by_email(params[:email])
        password = icebr8kr_user.password
      end
    end

    @user = existing_fb_user || icebr8kr_user ||
      User.new(first_name: params[:first_name],
                last_name: params[:last_name],
                 password: password ||= params[:password],
    password_confirmation: params[:password_confirmation] || password,
                   gender: params[:gender],
            date_of_birth: params[:date_of_birth],
                user_name: params[:user_name],
                    email: params[:email],
                   avatar: params[:avatar],
             facebook_uid: fb_user_id,
          facebook_avatar: params[:facebook_avatar])

    if fb_user_id
      # Check for namesake (the same user_name)
      if User.find_by_user_name(params[:user_name])
        @user.user_name += "_#{rand(10)}" until @user.valid?
      end
    end

    if !existing_fb_user
      @user.skip_confirmation! if fb_user_id # new facebook user

      if @user.save
        unless icebr8kr_user
          @user.send_facebook_password_email(password)
          info_mail = 'Message sent on your email, please check it'
        end
      else
        return render json: { errors: @user.errors.full_messages, success: false }, status: 200
      end
    end

    data = { user: @user, avatar: @user.avatar.url }
    if fb_user_id
      session = create_session @user, params[:auth]
      data[:authentication_token] = session[:auth_token]
    end

    render json: { success: true,
                      info: info_mail || "Logged in",
                      data: data,
                    status: 200 }
  end

  swagger_api :canned_statements do
    summary "Return all canned statement"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end

  def canned_statements
    @canned_statements = CannedStatement.all
  end

  swagger_api :upload_avatar do
    summary "Upload user's avatar"
    param :query, :avatar, :string, :optional, "User's avatar"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end

  def upload_avatar
    if @current_user.update_attribute(:avatar, params[:avatar])
      render json: { success: true,
                     info: 'Image successfully uploaded.',
                     status: 200 }
    else
      render json: { success: false,
                     info: 'Failed to upload image.',
                     status: 200 }
    end
  end

  swagger_api :edit_profile do
    summary "Edit profile of existing User"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, 'user[first_name]', :string, :required, "First name"
    param :query, 'user[last_name]', :string, :required, "Last name"
    param :query, 'user[gender]', :string, :required, "Gender"
    param :query, 'user[date_of_birth]', :date, :optional, "Date of birth"
    param :query, 'user[user_name]', :string, :required, "User name"
    param :query, 'user[email]', :string, :required, "Email address"
    param :query, 'user[password]', :string, :required, "Password"
    param :query, 'user[avatar]', :string, :optional, "User's avatar"
  end

  def edit_profile
    if @current_user.update_attributes!(user_params)
      render json: { success: true,
                     info: 'Profile successfully updated.',
                     user: @current_user,
                     status: 200 }
    else
      render json: { success: false,
                     info: 'Session expired. Please login.',
                     status: 200 }
    end
  end

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

    @users_in_radius     = User.near([lat, lng], 0.1).where.not(id: @current_user.id)
    @users_out_of_radius = User.near([lat, lng], 8).where.not(id: [@current_user.id] + @users_in_radius)
  end

  swagger_api :location do
    summary "Set location of current User"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, 'location[latitude]', :string, :required, "Latitude"
    param :query, 'location[longitude]', :string, :required, "Longitude"
  end

  def location
    lat = params[:location][:latitude]
    lng = params[:location][:longitude]

    if lat.nil? || lng.nil?
      render json: { success: false,
                     info: 'Latitude or Longitude are missed',
                     status: 200 }
    elsif @current_user.update_attributes(latitude: lat.gsub(',', '.'), longitude: lng.gsub(',', '.'))
      render json: { success: true,
                     info: 'New location was set successfully',
                     status: 200 }
    end
  end

  private

  def create_session user, auth
    range = [*'0'..'9', *'a'..'z', *'A'..'Z']
    session = {user_id: user.id, auth_token: Array.new(30){range.sample}.join, updated_at: Time.now}
    if auth && auth[:device].present? && auth[:device_token].present?
      session[:device] = auth['device']
      session[:device_token] = auth['device_token']
    end
    Session.create(session)
    session
  end


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
