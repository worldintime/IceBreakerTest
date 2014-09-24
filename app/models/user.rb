class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_many :sessions
  has_many :mutes
  has_many :conversations_my, class_name: Conversation, foreign_key: :sender_id
  has_many :conversations_his, class_name: Conversation, foreign_key: :receiver_id

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :avatar, styles: { thumb: '64x64' }, default_url: '/assets/avatar.png'
  validates_attachment :avatar, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates_presence_of :first_name, :last_name, :gender, :email, :user_name
  validates_confirmation_of :password
  validates_uniqueness_of :user_name

  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  def self.authenticate(param)
    user = User.find_for_authentication(email: param)
    user = User.find_for_authentication(user_name: param) if user.nil?
    user
  end

  def send_forgot_password_email!
    password = SecureRandom.hex(8)
    self.update_attributes(password: password, password_confirmation: password)
    scheduler = Rufus::Scheduler.new
    scheduler.at Time.now + 5.seconds do
      UserMailer.forgot_password(self, password).deliver
    end
  end

  def send_facebook_password_email(password)
    scheduler = Rufus::Scheduler.new
    scheduler.at Time.now + 5.seconds do
      UserMailer.facebook_password(self, password).deliver
    end
  end

  def self.from_omniauth(auth)
    where(auth.slice(:facebook_id)).first_or_initialize.tap do |user|
      user.facebook_id = auth.extra.raw_info.id if auth.extra.raw_info.id
      user.first_name = auth.info.first_name if auth.info.first_name
      user.last_name = auth.info.last_name if auth.info.last_name
      user.oauth_token = auth.credentials.token if auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
      user.email = auth.info.email if auth.info.email
      user.date_of_birth = Date.strptime(auth.extra.raw_info.birthday, "%m/%d/%Y") if auth.extra.raw_info.birthday
      user.gender = auth.extra.raw_info.gender if auth.extra.raw_info.gender
      # user.images = auth.info.images
      user.save(validate: false)
    end
  end

  def self.send_push_notification(options = {})
    user    = User.find options[:user_id]
    message = options[:message] ? options[:message] : "You have been ignored!"
    result  = false
    info    = 'Something went wrong'
 
     user.sessions.each do |session|
       if session.device && session.device_token
 
         if session.device == 'IOS'
           notification = Grocer::Notification.new(
             device_token: session.device_token,
             alert:        message
           )
           IceBr8kr::Application::IOS_PUSHER.push(notification)
           result = true
           info = 'Pushed to IOS'
         elsif session.device == 'Android'
           require 'rest_client'
           url = 'https://android.googleapis.com/gcm/send'
           headers = {
             'Authorization' => 'key=AIzaSyBCK9NX8gRY51g9UwtY1znEirJuZqTNmAU',
             'Content-Type'  => 'application/json'
           }
           request = {
             'registration_ids' => [session.device_token],
             data: {
               'message' => message
             }
           }
 
           response = RestClient.post(url, request.to_json, headers)
           result = true
           info = 'Pushed to Android'
         end
       end
     end
   end

  def self.rating_update(user_ids)
    sender   = self.find user_ids[:sender]
    receiver = self.find user_ids[:receiver]
    sender.update_attributes(sent_rating: sender.sent_rating + 1)
    receiver.update_attributes(received_rating: receiver.received_rating + 1)
  end

end
