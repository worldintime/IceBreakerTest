attributes :updated_at, :blocked_to
attribute :id => :conversation_id

node :opponent do
    partial("api/conversations/opponent", object: @history.opponent_identity(@current_user.id))
end

node :last_message do
    partial("api/conversations/last_message", object: @history)
end


