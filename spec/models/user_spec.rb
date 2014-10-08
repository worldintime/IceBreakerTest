require 'rails_helper'

describe User do
  it 'should validate' do
    validate_uniqueness_of :email
    validate_presence_of :user_name
    validate_presence_of :email
    validate_presence_of :first_name
    validate_presence_of :last_name
    validate_presence_of :gender
    validate_presence_of :date_of_birth
  end

  it 'should create user' do
    user = build :user
    expect(user.save).to be true
  end

  it 'should add address by location data' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    expect( user.address ).to match /NY/
  end

  it 'should place conversation to pending' do
    user = create(:user)
    expect{ user.place_to_pending(1, 2)
    }.to change(PendingConversation, :count).by(1)
  end

  it 'should remove conversation from pending' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    user2 = create(:user, latitude: 40.7127, longitude: -74.0059)
    user3 = create(:user, latitude: 40.0027, longitude: -74.6669)
    conversation = create(:conversation, sender_id: user.id, receiver_id: user2.id)
    pending1 = create( :pending_conversation, sender_id: user.id, receiver_id: user2.id, conversation_id: conversation.id)
    expect{ user.back_in_radius
    }.to change(PendingConversation, :count).by(-1)
    pending2 = create( :pending_conversation, sender_id: user.id, receiver_id: user3.id, conversation_id: conversation.id)
    expect{ user.back_in_radius
    }.to change(PendingConversation, :count).by(0)
  end

  it 'should return true or false if user in radius or out' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    user2 = create(:user, latitude: 40.7127, longitude: -74.0059)
    user3 = create(:user, latitude: 40.0027, longitude: -74.6669)

    expect( user.in_radius?(user2.id) ).to eq true
    expect( user.in_radius?(user3.id) ).to eq false
  end

end
