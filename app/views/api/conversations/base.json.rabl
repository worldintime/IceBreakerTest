attributes :updated_at, :blocked_to
attributes :last_message_text => :sender_id, :last_message_text => :text, :last_message_status => :status, :id => :conversation_id

node :opponent do
    partial("api/conversations/base2", object: @opponent.opponent_identity)
end