require 'rails_helper'

describe PendingConversation do

  it 'should validate' do
    validate_presence_of :sender_id
    validate_presence_of :receiver_id
    validate_presence_of :conversation_id
  end

  it 'should create conversation' do
    pending_conversation = build :pending_conversation
    expect(pending_conversation.save).to be true
    expect(pending_conversation.sender_id).to be 1
    expect(pending_conversation.receiver_id).to be 2
    expect(pending_conversation.conversation_id).to be 1
  end

end