class PendingConversation < ActiveRecord::Base
  validates_presence_of :sender_id, :receiver_id, :conversation_id
end
