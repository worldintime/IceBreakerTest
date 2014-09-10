class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  validates_uniqueness_of :email 
  validates_presence_of :first_name, :last_name, :gender, :email, :user_name
  validates_confirmation_of :password

  def self.from_omniauth(auth)
    where(auth.slice(:facebook_id)).first_or_initialize.tap do |user|
      user.facebook_id = auth.uid
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.email = auth.info.email
      user.date_of_birth = auth.info.birthday
      user.gender = auth.info.gender
      user.facebook_id = auth.info.uid
      # user.images = auth.info.images
      user.save(validate: false)
    end
  end
end
