class ForgotPassword < ActionMailer::Base
  default from: "from@example.com"

  def forgot_password(user, password)
    @user = user
    @password = password
    mail(to: @user.email, subject: 'New password for IceBr8kr account')
  end
end
