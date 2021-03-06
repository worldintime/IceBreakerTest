class User < ActiveRecord::Base
  has_many :sessions
  has_many :mutes
  has_many :conversations_my, class_name: Conversation, foreign_key: :sender_id
  has_many :conversations_his, class_name: Conversation, foreign_key: :receiver_id

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :async

  has_attached_file :avatar, styles: { thumb: '200x200#' }, default_url: '/assets/avatar.png', default_style: :thumb 
  validates_attachment :avatar, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif', 'application/octet-stream'] }
  validates_presence_of :first_name, :last_name, :gender, :email, :user_name
  validates_presence_of :password, on: :create
  validates_confirmation_of :password
  validates_uniqueness_of :user_name

  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode

  attr_reader :facebook_share_rating

  before_save :update_location_timestamp

  DISTANCE_IN_RADIUS     = 0.09144 # 100 yards in kilometers
  DISTANCE_OUT_OF_RADIUS = 8.047   # 5 miles in kilometers
  FEEDBACK_EMAIL         = "icebr8kr@gmail.com"

  # TODO: #register_or_login need test
  def register_or_login(user_info = {})
    new_fb_user      = user_info['new_fb_user']
    existing_fb_user = user_info['existing_fb_user']
    icebr8kr_user    = user_info['icebr8kr_user']
    new_regular_user = !new_fb_user && !existing_fb_user && !icebr8kr_user

    if new_fb_user
      self.skip_confirmation!
      password = SecureRandom.hex(4)
      self.update_attributes(password: password,
                password_confirmation: password)

      # Check for namesake (the same user_name)
      if User.find_by_user_name(user_info['user_name'])
        self.user_name += "_#{rand(10)}" until self.valid?
      end

      if self.save(validate: false)
        self.send_facebook_password_email password
        info_mail = 'Message with your new password was sent to your email'
      else
        return { success: false, errors: self.errors.full_messages, status: 200 }
      end
    elsif new_regular_user
      if self.save
        info_mail = 'Message with confirmation link was sent to your email'
      else
        return { success: false, errors: self.errors.full_messages, status: 200 }
      end
    end

    data = { user: self, avatar: self.avatar.url }
    if (new_fb_user || existing_fb_user || icebr8kr_user) && self.confirmed?
      session = self.create_session user_info['auth']
      data[:authentication_token] = session[:auth_token]
    elsif icebr8kr_user && !self.confirmed?
      info_mail = 'Please, confirm your email first'
    end

    { success: true,
         info: info_mail || "Logged in",
         data: data,
       status: 200 }
  end

  def conversations_history
    Conversation.where('(sender_id = ?  AND removed_by_sender = false) OR (receiver_id = ? AND removed_by_receiver = false)', self.id, self.id)
  end

  def in_radius?(user_id)
    User.near([self.latitude, self.longitude], 0.1).where(id: user_id).present?
  end

  def place_to_pending(conversation_id, user_id)
    pend = PendingConversation.new(conversation_id: conversation_id, receiver_id: user_id, sender_id: self.id)
    pend.save
  end

  def back_in_radius
    returned_users = PendingConversation.where(sender_id: self.id).pluck(:receiver_id).uniq
    returned_users.each do |user_id|
      if User.near([self.latitude, self.longitude], 0.1).where(id: user_id).present?
        user = User.find_by(id: user_id)
        pending_conversation = PendingConversation.where(sender_id: self.id, receiver_id: user_id)
        initial = Conversation.find_by(id: pending_conversation.pluck(:conversation_id).uniq.first)
        not_muted = Mute.where(sender_id: [self.id, user_id], receiver_id: [self.id, user_id]).blank?
        case not_muted
          when pending_conversation.first.conversation_id == 0
            User.send_push_notification(user_id: self.id, message: "#{user.user_name} is back in radius", back_in_radius: true)
            pending_conversation.destroy_all
          when initial.present?
            User.send_push_notification(user_id: self.id, message: "#{user.user_name} is back in radius", back_in_radius: true)
            User.send_push_notification(user_id: user.id, message: "#{self.user_name} is back in radius", back_in_radius: true)
            pending_conversation.destroy_all
        end
      end
    end
  end

  def create_session auth
    range = [*'0'..'9', *'a'..'z', *'A'..'Z']
    session = {user_id: self.id, auth_token: Array.new(30){range.sample}.join, updated_at: Time.now}
    if auth && auth['device'].present? && auth['device_token'].present?
      session[:device] = auth['device']
      session[:device_token] = auth['device_token']
    end
    Session.where(user_id: self.id).destroy_all
    Session.create(session)
    session
  end

  def send_forgot_password_email!
    password = SecureRandom.hex(4)
    self.update_attributes(password_code: password)
    UserMailer.delay.forgot_password(self, password)
  end

  def send_facebook_password_email(password)
    UserMailer.delay.facebook_password(self, password)
  end

  def send_feedback(message)
    UserMailer.delay.feedback(self, message)
  end

  def facebook_share_rating
    self.facebook_rating.to_i >= 10 ? self.update_attributes(facebook_rating: self.facebook_rating.to_i - 10) : false
  end

  def search_results(current_user_id)
    status = Conversation.where("status = ? AND sender_id = ? AND receiver_id = ? OR status = ? AND sender_id = ? AND receiver_id = ?", 'Closed',
                                current_user_id, self.id, 'Closed', self.id, current_user_id ).to_a
    status.blank? ? 'Open' : 'Closed'
  end

  def set_location(lat, lng)
    if lat.nil? || lng.nil?
      { success: false,
        info: 'Latitude or Longitude are missed',
        status: 200 }
    elsif self.update_attributes(latitude: lat.gsub(',', '.'), longitude: lng.gsub(',', '.'))
	self.back_in_radius
      { success: true,
        info: 'New location was set successfully',
        status: 200 }
    else
      { success: false,
        info: self.errors.full_messages,
        status: 200 }
    end
  end

  # FIXES: response need move to json view
  def reset_location!
    begin
      self.update_attributes!(latitude: nil, longitude: nil, address: nil)
      { success: true,
        info: 'Location was reset successfully',
        status: 200 }
    rescue Exception => e
      { success: false,
        info: e.message,
        status: 200 }
    end
  end

  def blocked_to(current_user_id)
    muted = Mute.where( "sender_id = ? AND receiver_id = ? OR sender_id = ? AND receiver_id = ?",
                        self.id, current_user_id, current_user_id, self.id )
    if muted.blank?
      { blocked_to: 'No',
        blocked_status: 'No'}
    else
      start_time = muted.first.created_at.to_time
      passed_time = TimeDifference.between(Time.now, start_time).in_minutes
      { blocked_to: Mute::TIMER - passed_time,
        blocked_status: muted.first.status }
    end
  end

  private

  def update_location_timestamp
    self.location_updated_at = Time.now if self.latitude_changed? || self.longitude_changed?
  end

  class << self
    def authenticate(param)
      user = User.find_for_authentication(email: param)
      user = User.find_for_authentication(user_name: param) if user.nil?
      user
    end

    def send_push_notification(options = {})
      user    = User.find options[:user_id]
      message = options[:message] ? options[:message] : "You have been ignored!"
      result  = false
      info    = 'Something went wrong'

      user.sessions.each do |session|
        if session.device && session.device_token

          if session.device.downcase == 'ios'
            notification = Grocer::Notification.new(
                device_token: session.device_token,
                alert:        message,
		sound:        "default",
                badge:        Conversation.unread_messages(options[:user_id]),
		custom: {back_in_radius: options[:back_in_radius] ? true : false} 	
            )
            IceBr8kr::Application::IOS_PUSHER.push(notification)
            result = true
            info = 'Pushed to IOS'
          elsif session.device.downcase == 'android'
            require 'rest_client'
            url = 'https://android.googleapis.com/gcm/send'
            headers = {
                'Authorization' => 'key=AIzaSyBCK9NX8gRY51g9UwtY1znEirJuZqTNmAU',
                'Content-Type'  => 'application/json'
            }
            request = {
                'registration_ids' => [session.device_token],
                data: {
		    'title' => 'IceBr8kr',			
                    'message' => message,
		    'back_in_radius' => options[:back_in_radius] ? true : false
 		}
            }

            response = RestClient.post(url, request.to_json, headers)
            result = true
            info = 'Pushed to Android'
          end
        end
      end
    end

    def rating_update(user_ids)
      sender   = self.find user_ids[:sender]
      receiver = self.find user_ids[:receiver]
      sender.update_attributes(sent_rating: sender.sent_rating + 1)
      receiver.update_attributes(received_rating: receiver.received_rating + 1, facebook_rating: receiver.facebook_rating.to_i + user_ids[:fb_rating].to_i)
    end

    def reset_location
      where(["location_updated_at < ? AND latitude IS NOT NULL AND longitude IS NOT NULL", (Time.now - 1.minute)]).update_all(latitude: nil, longitude: nil, address: nil)
    end
  end

end
