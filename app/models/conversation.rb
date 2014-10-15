class Conversation < ActiveRecord::Base
  belongs_to :sender, class_name: User, foreign_key: :sender_id
  belongs_to :receiver, class_name: User, foreign_key: :receiver_id
  has_one :mute, foreign_key: :conversation_id

  validates_presence_of :sender_id, :receiver_id

  before_create :attr_by_default
  before_update :mute_users

  attr_accessor :current_user
  attr_reader :last_message_text, :last_message_status, :last_message_sender, :blocked_to, :opponent_identity

  include ActionView::Helpers::DateHelper

  def check_if_already_received?(sender_id, receiver_id)
    Conversation.where(sender_id: receiver_id, receiver_id: sender_id,
                       created_at: (30.minutes.ago..Time.now)).blank?
  end

  def ignore_user sender_id, receiver_id
    ignore = Mute.new(sender_id: sender_id, receiver_id: receiver_id, conversation_id: self.id, status: 'Ignored')
    ignore.save
    Mute.delay(run_at: 1.hour.from_now.getutc).destroy(ignore.id)
  end

  # FIXME: #to_json and all relater methods need refactoring

  def last_message_from_sender
    @last_message ||= [{ text: self.initial, status: 'initial' },
                       { text: self.reply, status: 'reply' },
                       {  text: self.finished, status: 'finished'}
                      ].delete_if{ |item| item[:text].blank? }.last
  end

  def last_message_text
    last_message_from_sender[:text]
  end

  def last_message_status
    last_message_from_sender[:status]
  end

  def last_message_sender
    self.finished.nil? && self.initial != nil ? self.receiver_id : self.sender_id
  end

  def existing_messages
    if self.reply.nil? && self.finished.nil?
      {initial_viewed: true}
    elsif self.finished.nil?
      {reply_viewed: true}
    else
      {finished_viewed: true}
    end
  end

  def blocked_to
    if self.mute
      if self.mute.status == 'Muted'
        start_time = self.mute.created_at
        distance_of_time_in_words(start_time, Time.now)
      elsif self.mute.status == 'Ignored'
        start_time = self.mute.created_at
        start_time = start_time + 1.hours
        distance_of_time_in_words(start_time, Time.now)
      end
    else
      'No'
    end
  end

  def opponent_identity
    if self.sender_id != current_user
      opponent = User.find(self.sender_id)
      {     opponent_id: opponent.id,
             first_name: opponent.first_name,
              last_name: opponent.last_name,
            user_avatar: opponent_avatar,
              user_name: opponent.user_name,
        facebook_avatar: opponent.facebook_avatar
      }
    else
      opponent = User.find(self.receiver_id)
      {     opponent_id: opponent.id,
             first_name: opponent.first_name,
              last_name: opponent.last_name,
            user_avatar: opponent_avatar,
              user_name: opponent.user_name,
        facebook_avatar: opponent.facebook_avatar
      }
    end
  end

  def check_if_sender(current_user_id)
    receiver = User.find(self.receiver_id)
    sender = User.find(self.sender_id)

    if self.sender_id != current_user_id
      { opponent:  {id: sender.id,
                    email: sender.email,
                    first_name: sender.first_name,
                    last_name: sender.last_name,
                    avatar: sender.avatar.url(:thumb),
                    initial: self.initial,
                    finished: self.finished,
                    user_name: sender.user_name,
                    facebook_avatar: sender.facebook_avatar},
        my_message: {id: receiver.id,
                     reply: self.reply}


      }
    else
      { opponent:  {id: receiver.id,
                    email: receiver.email,
                    first_name: receiver.first_name,
                    last_name: receiver.last_name,
                    avatar: receiver.avatar.url(:thumb),
                    reply: self.reply,
                    user_name: receiver.user_name,
                    facebook_avatar: receiver.facebook_avatar},
        my_message: {id: sender.id,
                     initial: self.initial,
                     finished: self.finished}
      }
    end
  end

  def opponent_avatar
    friend_id = [sender_id,receiver_id].select{|id| id != current_user}
    @user_avatar ||= User.find(friend_id).first.avatar.url(:thumb)
  end

  private

  def attr_by_default
    self.initial_viewed = false
    self.reply_viewed = true
    self.finished_viewed = true
    nil
  end

  def mute_users
    if self.finished_changed?
      mute = Mute.new(sender_id: self.sender_id, receiver_id: self.receiver_id, conversation_id: self.id, status: 'Muted')
      mute.save
      Mute.delay(run_at: 1.hour.from_now.getutc).destroy(mute.id)
    end
  end

  class << self
    def unread_messages(current_user_id)
      query1 = "SELECT SUM((CASE WHEN reply_viewed = false THEN 1 ELSE 0 END)) AS reply_sum FROM conversations WHERE (conversations.sender_id = #{current_user_id})"
      query2 = "SELECT SUM((CASE WHEN initial_viewed = false THEN 1 ELSE 0 END) + (CASE WHEN finished_viewed = false THEN 1 ELSE 0 END)) AS total_sum FROM conversations WHERE (conversations.receiver_id = #{current_user_id})"
      reply = connection.execute(query1).to_a.first['reply_sum'].to_i
      initial = connection.execute(query2).to_a.first['total_sum'].to_i
      sum = initial + reply
    end
  end

end
