class Api::PasswordsController < Devise::ConfirmationsController

  def index
    flash[:notice] = "Password successfully changed. You can use it in app."
  end

  def edit
    @user = User.find_by(password_code: params[:reset_password_token])
  end

  def update
    user = User.find_by(password_code: user_params[:reset_password_token])
    if user.update_attributes(user_params.except(:reset_password_token))
      render :index
    else
      flash[:notice] = 'Password confirmation didnt match.'
      redirect_to "/users/password/edit?reset_password_token=#{user_params[:reset_password_token]}"
    end
  end


  private
    def user_params
      params.require(:user).permit(:reset_password_token, :password, :password_confirmation, :password_code)
    end
end
