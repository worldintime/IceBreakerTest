class Api::UsersController < ApplicationController

  def create

    user = User.new(first_name: params[:first_name], last_name: params[:last_name], password: params[:password],
                    gender: params[:gender], date_of_birth: params[:date_of_birth], user_name: params[:user_name],
                    password_confirmation: params[:password_confirmation], email: params[:email])

    if user.save
      render json: {success: true,
                    info: 'Message sent on your email, please check it',
                    data: {user: user},
                    status: 200
      }
    else
      render json: user.errors.full_messages, status: 200
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
                                 :user_name, :password, :password_confirmation)
  end

end
