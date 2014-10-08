require 'rails_helper'

describe Conversation do

  it 'should validate' do
    validate_presence_of :sender_id
    validate_presence_of :receiver_id
  end

  it 'should create conversation' do
    conversation = build :conversation
    expect(conversation.save).to be true
    expect(conversation.initial_viewed).to eq false
  end

end