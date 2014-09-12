class Conversation < ActiveRecord::Base
  belongs_to :sender, class_name: User, foreign_key: :sender_id
  belongs_to :receiver, class_name: User, foreign_key: :receiver_id
  has_many :mutes
  before_create :attr_by_default
  before_update :mute_users
  validates_presence_of :sender_id, :receiver_id

  def attr_by_default
    self.initial_viewed = false
    self.reply_viewed = false
    self.finished_viewed = false
    nil
  end

  def mute_users
    if self.finished_changed?
      mute = self.mutes.new(sender_id: self.sender_id, receiver_id: self.receiver_id, conversation_id: self.id)
      mute.save
      scheduler = Rufus::Scheduler.new
      scheduler.at Time.now + 1.hours do
        Mute.find_by_id(mute.id).destroy
      end
    end
  end

  def ignore_user
    ignore = self.mutes.new(sender_id: self.sender_id, receiver_id: self.receiver_id, converstion_id: self.id)
    ignore.save
    scheduler = Rufus::Scheduler.new
    scheduler.at Time.now + 4.hours do
      Mute.find_by_id(ignore.id).destroy
    end
  end

end
