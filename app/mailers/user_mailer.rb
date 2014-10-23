class UserMailer < Devise::Mailer

  default from: "icebr8kr@gmail.com"

  def forgot_password(user, password)
    @user = user
    @password = password
    mail(to: @user.email, subject: 'New password for IceBr8kr account')
  end

  def facebook_password(user, password)
    @user = user
    @password = password
    mail(to: @user.email, subject: 'Password and user name for IceBr8kr account')
  end

  def confirmation_instructions(record, token, opts={})
    super
  end
end
