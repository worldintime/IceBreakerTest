class Conversation < ActiveRecord::Base
  belongs_to :sender, class_name: User, foreign_key: :sender_id
  belongs_to :receiver, class_name: User, foreign_key: :receiver_id

  before_create :attr_by_default

  def attr_by_default
    self.initial_viewed = false
    self.reply_viewed = false
    self.finished = false
    nil
  end

end
