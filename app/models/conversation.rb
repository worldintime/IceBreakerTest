class Conversation < ActiveRecord::Base
  belongs_to :sender, class_name: User, foreign_key: :sender_id
  belongs_to :receiver, class_name: User, foreign_key: :receiver_id
  has_one :mute, foreign_key: :conversation_id

  validates_presence_of :sender_id, :receiver_id

  before_create :attr_by_default
  before_update :mute_users

  attr_reader :last_message_text, :last_message_status, :last_message_sender, :last_message_unread, :blocked_to, :opponent_identity

  include ActionView::Helpers::DateHelper

  def remove_conversation(current_user_id)
    self.update_attributes!(status: 'Deleted')
    case
      when self.removed_by_sender == true && self.receiver_id == current_user_id
        self.destroy
      when self.removed_by_receiver == true && self.sender_id == current_user_id
        self.destroy
      when self.removed_by_sender == false && self.removed_by_receiver == false
        self.sender_id == current_user_id ? self.update_attributes!(removed_by_sender: true) : self.update_attributes!(removed_by_receiver: true)
    end
  end

  def check_if_already_received?(sender_id, receiver_id)
    Conversation.where(sender_id: [receiver_id,sender_id], receiver_id: [sender_id,receiver_id],
                       created_at: (30.minutes.ago..Time.now)).blank?
  end

  def ignore_user sender_id, receiver_id
    ignore = Mute.new(sender_id: sender_id, receiver_id: receiver_id, conversation_id: self.id, status: 'Ignored')
    ignore.save
    Mute.delay(run_at: Mute::TIMER.minutes.from_now.getutc).destroy(ignore.id)
  end

  def last_message_from_sender
    @last_message ||= [{ text: self.initial, status: 'initial', sender_id: self.sender_id, unread: self.initial_viewed },
                       { text: self.reply, status: 'reply', sender_id: receiver_id, unread: self.reply_viewed },
                       {  text: self.finished, status: 'finished', sender_id: self.sender_id, unread: self.finished_viewed}
                      ].delete_if{ |item| item[:text].blank? }.last
  end

  def last_message_text
    last_message_from_sender[:text]
  end

  def last_message_status
    last_message_from_sender[:status]
  end

  def last_message_sender
    last_message_from_sender[:sender_id]
  end

  def last_message_unread
    last_message_from_sender[:unread]
  end

  def existing_messages
    if self.reply.nil? && self.finished.nil?
      self.update_column(:initial_viewed, true)
    elsif self.finished.nil?
      self.update_column(:initial_viewed, true)
      self.update_column(:reply_viewed, true)
    else
      self.update_column(:initial_viewed, true)
      self.update_column(:finished_viewed, true)
    end
  end

  def blocked_to
    if self.mute
      if self.mute.status == 'Muted'
        start_time = self.mute.created_at
        distance_of_time_in_words(start_time, Time.now)
      elsif self.mute.status == 'Ignored'
        start_time = self.mute.created_at
        start_time = start_time + Mute::TIMER.minutes
        distance_of_time_in_words(start_time, Time.now)
      end
    else
      'No'
    end
  end

  def opponent_identity(current_user_id)
    if self.sender_id != current_user_id
      opponent = User.find(self.sender_id)
    else
      opponent = User.find(self.receiver_id)
    end
  end

  def my_message(current_user_id)
    if self.sender_id != current_user_id
      { reply: self.reply,
        reply_sent_at: self.reply_created_at
      }
    else
      { initial: self.initial,
        initial_sent_at: self.initial_created_at,
        finished: self.finished,
        finished_sent_at: self.finished_created_at
      }
    end
  end

  private

  def attr_by_default
    self.initial_viewed = false
    self.reply_viewed = true
    self.finished_viewed = true
    nil
  end

  def mute_users
    if self.finished_changed? || self.removed_by_receiver_changed? || self.removed_by_sender_changed?
      return true if self.finished.present? && self.removed_by_receiver && self.removed_by_sender
      mute = Mute.new(sender_id: self.sender_id, receiver_id: self.receiver_id, conversation_id: self.id, status: 'Muted')
      mute.save
      Mute.delay(run_at: Mute::TIMER.minutes.from_now.getutc).destroy(mute.id)
    end
  end

  class << self
    def unread_messages(current_user_id)
      query1 = "SELECT SUM((CASE WHEN reply_viewed = false THEN 1 ELSE 0 END)) AS reply_sum FROM conversations WHERE (conversations.sender_id = #{current_user_id} AND removed_by_sender = false)"
      query2 = "SELECT SUM((CASE WHEN initial_viewed = false THEN 1 ELSE 0 END) + (CASE WHEN finished_viewed = false THEN 1 ELSE 0 END)) AS total_sum FROM conversations WHERE (conversations.receiver_id = #{current_user_id} AND removed_by_receiver = false)"
      reply = connection.execute(query1).to_a.first['reply_sum'].to_i
      initial = connection.execute(query2).to_a.first['total_sum'].to_i
      sum = initial + reply
    end
  end

end
