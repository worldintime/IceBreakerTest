require 'rails_helper'

describe Api::ConversationsController do
  let(:user){ auth_user! }
  let(:user2){ auth_user! }

  describe '#messaging :initial' do
    before :each do
      @params = { authentication_token: user.sessions.first.auth_token,
                  sender_id: user.id,
                  receiver_id: user2.id,
                  type: 'initial',
                  msg: 'Hi' }
    end

    it 'should create new' do
      expect{
        post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: user.id,
             receiver_id: user2.id, type: 'initial', msg: 'initial'
      }.to change(Conversation, :count).by(1)
      expect( Oj.load(response.body)['success'] ).to eq true
      user2.reload
      expect(user2.facebook_rating).to eq(1)
    end

    it 'already received' do
      Conversation.create(sender: user2, receiver: user, created_at: 5.minutes.ago)
      post :messaging, @params
      expect(Oj.load(response.body)['info']).to eq 'This user already sent a digital hello to you few minutes ago'
    end
   end

  describe 'conversation' do
    let(:user){ auth_user! }
    let(:user2){ auth_user! }
    let(:conversation){ create(:conversation, id: id = rand(100))}

    it 'should receive reply' do
      post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: user2.id,
                       receiver_id: user.id, type: 'reply', msg: 'reply', conversation_id: conversation.id
        expect(conversation.reload.reply).to eq 'reply'
        expect(conversation.reload.status).to eq 'Closed'
    end

    describe 'with mute' do
      before :each do
        stub_mute_destroy_task
      end

      it 'should receive last message' do
        expect{
          post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: user.id,
               receiver_id: user2.id, type: 'finished', msg: 'finished', conversation_id: conversation.id
        }.to change(Mute, :count).by(1)

        conversation.reload
        expect(conversation.finished).to eq 'finished'
        expect(conversation.status).to eq 'Open'
      end

      it 'should ignore user' do
        expect{
          post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: user.id,
               receiver_id: user2.id, type: 'ignore', conversation_id: conversation.id
        }.to change(Mute, :count).by(1)
      end

      it 'should mute user' do
        Mute.create!(sender_id: user.id, receiver_id: user2.id)
        post :messaging, authentication_token: user.sessions.first.auth_token,
             sender_id: user.id,
             receiver_id: user2.id
        expect(Oj.load(response.body)['info']).to eq 'You have been muted with this user'
      end
    end

    it 'should block if users out of radius' do

      conv = FactoryGirl.create(:conversation, sender_id: user.id, receiver_id: user2.id,
                                initial: 'initial', reply: nil,finished: nil)
      user.latitude = 48.63
      user.longitude = 22.39
      user.save
      user2.latitude = 48.23
      user2.longitude = 22.19
      user2.save
      expect{
        post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: user.id,
             receiver_id: user2.id, type: 'reply', conversation_id: conversation.id
      }.to change(PendingConversation, :count).by(1)
      expect(conversation.reply).to eq nil
    end

    it 'should receive conversation detail' do
      conv = FactoryGirl.create(:conversation, sender_id: user.id, receiver_id: user2.id,
                                initial: 'initial', reply: 'reply',finished: 'finished')
      post :conversation_detail, authentication_token: user.sessions.first.auth_token,
                                 conversation_id: conv.id
      expect( Oj.load(response.body)['data']['opponent']['id'] ).to eq user2.id
      expect( Oj.load(response.body)['data']['opponent']['first_name'] ).to eq user2.first_name
      expect( Oj.load(response.body)['data']['opponent']['last_name'] ).to eq user2.last_name
      expect( Oj.load(response.body)['data']['opponent']['email'] ).to eq user2.email
      expect( Oj.load(response.body)['data']['opponent']['reply'] ).to eq 'reply'

      expect( Oj.load(response.body)['data']['my_message']['id'] ).to eq user.id
      expect( Oj.load(response.body)['data']['my_message']['initial'] ).to eq 'initial'
      expect( Oj.load(response.body)['data']['my_message']['finished'] ).to eq 'finished'
    end

    describe 'Rabl views' do

      render_views

      it 'should receive conversation history' do

        conv = FactoryGirl.create( :conversation, sender_id: user.id, receiver_id: user2.id, initial: 'initial',
                                  reply: 'reply', finished: 'finished' )
        post :history_of_digital_hello, authentication_token: user.sessions.first.auth_token, format: 'json'

        expect( Oj.load(response.body)['data']['conversation0']['conversation_id'] ).to eq conv.id
        expect( Oj.load(response.body)['data']['conversation0']['blocked_to'] ).to eq 'No'
        expect( Oj.load(response.body)['data']['conversation0']['opponent']['opponent_id'] ).to eq user2.id
        expect( Oj.load(response.body)['data']['conversation0']['opponent']['first_name'] ).to eq user2.first_name
        expect( Oj.load(response.body)['data']['conversation0']['opponent']['last_name'] ).to eq user2.last_name
        expect( Oj.load(response.body)['data']['conversation0']['opponent']['user_name'] ).to eq user2.user_name
        expect( Oj.load(response.body)['data']['conversation0']['opponent']['user_avatar'] ).to eq user2.avatar.url
        expect( Oj.load(response.body)['data']['conversation0']['opponent']['facebook_avatar'] ).to eq user2.facebook_avatar
        expect( Oj.load(response.body)['data']['conversation0']['last_message']['sender_id'] ).to eq user.id
        expect( Oj.load(response.body)['data']['conversation0']['last_message']['text'] ).to eq 'finished'
        expect( Oj.load(response.body)['data']['conversation0']['last_message']['status'] ).to eq 'finished'

      end

    end

    it 'should receive number of unread messages' do
      conv1 = FactoryGirl.create(:conversation, sender_id: user.id, initial: 'initial', reply: 'reply',
                                finished: 'finished')
      conv2 = FactoryGirl.create(:conversation, receiver_id: user.id, initial: 'initial', reply: 'reply',
                                finished: 'finished')

      conv1.reply_viewed = false
      conv1.finished_viewed = false
      conv1.save
      conv2.reply_viewed = false
      conv2.finished_viewed = false
      conv2.save
      post :unread_messages, authentication_token: user.sessions.first.auth_token
      expect( Oj.load(response.body)['success'] ).to eq true
      expect( Oj.load(response.body)['data'] ).to eq 3
    end

  end

end
