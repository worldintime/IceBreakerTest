class Conversation < ActiveRecord::Base
  belongs_to :sender, class_name: User, foreign_key: :sender_id
  belongs_to :receiver, class_name: User, foreign_key: :receiver_id
  has_one :mute, foreign_key: :conversation_id
  before_create :attr_by_default
  before_update :mute_users
  validates_presence_of :sender_id, :receiver_id

  include ActionView::Helpers::DateHelper

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
      scheduler = Rufus::Scheduler.new
      scheduler.at Time.now + 1.hours do
        Mute.find(mute.id).destroy
      end
    end
  end

  def ignore_user sender_id, receiver_id
    ignore = Mute.new(sender_id: sender_id, receiver_id: receiver_id, conversation_id: self.id, status: 'Ignored')
    ignore.save
    scheduler = Rufus::Scheduler.new
    scheduler.at Time.now + 1.hours do
      Mute.find(ignore.id).destroy
    end
  end

  def to_json(current_user_id)
    opponent_identity(current_user_id).merge(conversation_status_for_json(current_user_id))
  end

  def conversation_status_for_json(current_user_id)
    {blocked_to: blocked_to(current_user_id),
     conversation_id: self.id,
     updated_at: self.updated_at}
  end

  def last_message_from_sender
    if self.finished.nil? && self.reply.nil?
      {sender_id: self.sender_id,
       text: self.initial,
       status: 'initial'}
    elsif self.finished.nil? && self.initial != nil
      {sender_id: self.receiver_id,
       text: self.reply,
       status: 'reply'}
    else
      {sender_id: self.sender_id,
       text: self.finished,
       status: 'finished'}
    end
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

  def self.unread_messages(current_user_id)
    query1 = "SELECT SUM((CASE WHEN reply_viewed = false THEN 1 ELSE 0 END)) AS reply_sum FROM conversations WHERE (conversations.sender_id = #{current_user_id})"
    query2 = "SELECT SUM((CASE WHEN initial_viewed = false THEN 1 ELSE 0 END) + (CASE WHEN finished_viewed = false THEN 1 ELSE 0 END)) AS total_sum FROM conversations WHERE (conversations.receiver_id = #{current_user_id})"
    reply = connection.execute(query1).to_a.first['reply_sum'].to_i
    initial = connection.execute(query2).to_a.first['total_sum'].to_i
    sum = initial + reply
  end

  def blocked_to(current_user_id)
    if self.mute
      if self.mute.status == 'Muted'
        start_time = self.mute.created_at
        distance_of_time_in_words(start_time, Time.now)
      elsif self.mute.status == 'Ignored'
        start_time = self.mute.created_at
        start_time = start_time + 4.hours
        distance_of_time_in_words(start_time, Time.now)
      end
    else
      'No'
    end
  end

  def ignored
    if Mute.find_by_conversation_id(self.id)
      true
    else
      false
    end
  end

  def opponent_identity(current_user_id)
    if self.sender_id != current_user_id
      opponent = User.find(self.sender_id)
      { opponent: { opponent_id: opponent.id,
                    first_name: opponent.first_name,
                    last_name: opponent.last_name,
                    user_avatar: receiver_avatar(current_user_id),
                    user_name: opponent.user_name
      },
        last_message: last_message_from_sender
      }
    else
      opponent = User.find(self.receiver_id)
      { opponent:  { opponent_id: opponent.id,
                     first_name: opponent.first_name,
                     last_name: opponent.last_name,
                     user_avatar: receiver_avatar(current_user_id),
                     user_name: opponent.user_name
      },
        last_message: last_message_from_sender

      }
    end
  end

  def check_if_sender(current_user_id)
    receiver = User.find(self.receiver_id)
    sender = User.find(self.sender_id)

    if self.sender_id != current_user_id
      { opponent:  {id: sender.id,
                    avatar: sender.avatar.url,
                    email: sender.email,
                    first_name: sender.first_name,
                    last_name: sender.last_name,
                    avatar: sender.avatar.url,
                    initial: self.initial,
                    finished: self.finished,
                    user_name: sender.user_name},
        my_message:  {id: receiver.id,
                      reply: self.reply}


      }
    else
      { opponent:  {id: receiver.id,
                    avatar: receiver.avatar.url,
                    email: receiver.email,
                    first_name: receiver.first_name,
                    last_name: receiver.last_name,
                    avatar: receiver.avatar.url,
                    reply: self.reply,
                    user_name: receiver.user_name},
        my_message:  {id: sender.id,
                      initial: self.initial,
                      finished: self.finished}
      }
    end
  end

  def receiver_avatar(current_user_id)
    friend_id = [sender_id,receiver_id].select{|id| id != current_user_id}
    @user_avatar ||= User.find(friend_id).first.avatar.url
  end

end