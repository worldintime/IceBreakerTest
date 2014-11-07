collection false

node :success do
  true
end

node :data do
  { opponent: partial("api/conversations/conversation_detail/opponent", object: @opponent).merge(@opponent_message),
    my_message: partial("api/conversations/conversation_detail/my_message", object: @current_user).merge(@my_message) }
end

node :conversation_id do
  @conversation.id
end