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
  describe 'facebook_rating' do
    it 'should return true if facebook rating equals 10 or more' do
      user = create(:user, facebook_rating: 13)

      expect( user.facebook_share_rating).to eq true
      expect( user.facebook_rating).to eq 3
    end

    it 'should return false if facebook rating less then 10' do
      user = create(:user, facebook_rating: 9)

      expect( user.facebook_share_rating).to eq false
      expect( user.facebook_rating).to eq 9
    end
  end
  it 'should raise receivers rating by 1 when he receives initial hello' do
    user1 = create(:user, facebook_rating: 9)
    user2 = create(:user, facebook_rating: 13)

    expect( User.rating_update( {sender: user1.id, receiver: user2.id, fb_rating: 1} ) ).to eq true
    user2.reload
    expect( user2.facebook_rating).to eq 14

  end

end
