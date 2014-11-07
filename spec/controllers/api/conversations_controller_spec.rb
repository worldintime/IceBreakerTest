require 'rails_helper'

describe Api::ConversationsController do
  let(:user){ auth_user! }
  let(:user2){ auth_user! }
  let(:auth_token){ user.sessions.first.auth_token }

  before :each do
    @params = { authentication_token: auth_token,
                sender_id: user.id,
                receiver_id: user2.id,
                type: 'initial',
                msg: 'Hi' }
  end

  describe '#messaging :initial' do
    it 'should create new' do
      expect{
        post :messaging, @params
      }.to change(Conversation, :count).by(1)
      expect( Oj.load(response.body)['success'] ).to be_truthy
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
    let(:conversation){ create(:conversation)}

    before :each do
      @params.merge!(conversation_id: conversation.id)
    end

    it 'should receive reply' do
      post :messaging, @params.merge(sender_id: user2.id,
                                     receiver_id: user.id,
                                     type: 'reply',
                                     msg: 'reply')

      expect(conversation.reload.reply).to eq 'reply'
      expect(conversation.reload.status).to eq 'Closed'
    end

    describe 'with mute' do
      before :each do
        stub_mute_destroy_task
      end

      it 'should receive last message' do
        expect{
          post :messaging, @params.merge(type: 'finished', msg: 'finished')
        }.to change(Mute, :count).by(1)

        conversation.reload
        expect(conversation.finished).to eq 'finished'
        expect(conversation.status).to eq 'Open'
      end

      it 'should ignore user' do
        expect{
          post :messaging, @params.merge(type: 'ignore')
        }.to change(Mute, :count).by(1)
      end

      it 'should mute user' do
        muted = Mute.create!(sender_id: user.id, receiver_id: user2.id)
        post :messaging, @params.merge(type: nil, msg: nil)
        expect(Oj.load(response.body)['info']).to eq "You have #{muted.blocked_timer} minutes before another conversation can be started!"
      end
    end

    it 'should block if users out of radius' do
      conv = FactoryGirl.create(:conversation, sender_id: user.id,
                                               receiver_id: user2.id,
                                               initial: 'initial',
                                               reply: nil,
                                               finished: nil)
      user.latitude = 48.63
      user.longitude = 22.39
      user.save!
      user2.latitude = 48.23
      user2.longitude = 22.19
      user2.save!
      expect{
        post :messaging, @params.merge(type: 'reply', conversation_id: conv.id)
      }.to change(PendingConversation, :count).by(1)
      expect(conv.reply).to be_nil
    end

    it 'should receive conversation detail' do
      conv = FactoryGirl.create(:conversation, sender_id: user.id,
                                               receiver_id: user2.id,
                                               initial: 'initial',
                                               reply: 'reply',
                                               finished: 'finished')

      post :conversation_detail, authentication_token: auth_token,
                                 conversation_id: conv.id

      json = Oj.load(response.body)['data']
      opponent = json['opponent']
      my_message = json['my_message']
      expect( opponent['id'] ).to eq user2.id
      expect( opponent['first_name'] ).to eq user2.first_name
      expect( opponent['last_name'] ).to eq user2.last_name
      expect( opponent['email'] ).to eq user2.email
      expect( opponent['reply'] ).to eq 'reply'

      expect( my_message['id'] ).to eq user.id
      expect( my_message['initial'] ).to eq 'initial'
      expect( my_message['finished'] ).to eq 'finished'
    end

    describe 'Rabl render' do
      render_views

      it 'should receive conversation history' do
        conv = FactoryGirl.create(:conversation, sender_id: user.id,
                                                 receiver_id: user2.id,
                                                 initial: 'initial',
                                                 reply: 'reply',
                                                 finished: 'finished')

        post :history_of_digital_hello, authentication_token: auth_token, format: 'json'

        conv.reload
        json = Oj.load(response.body)
        conversation0 = json['data']['conversation0']
        expect( json['success'] ).to be_truthy
        expect( json['fb_share'] ).to be_falsey
        expect( json['status'] ).to eq 200
        expect( conversation0['updated_at'].to_json ).to eq conv.updated_at.to_json
        expect( conversation0['blocked_to'] ).to eq 'No'
        expect( conversation0['conversation_id'] ).to eq conv.id
        expect( conversation0['opponent']['opponent_id'] ).to eq user2.id
        expect( conversation0['opponent']['first_name'] ).to eq user2.first_name
        expect( conversation0['opponent']['last_name'] ).to eq user2.last_name
        expect( conversation0['opponent']['user_name'] ).to eq user2.user_name
        expect( conversation0['opponent']['user_avatar'] ).to eq user2.avatar.url
        expect( conversation0['opponent']['facebook_avatar'] ).to eq user2.facebook_avatar
        expect( conversation0['last_message']['sender_id'] ).to eq user.id
        expect( conversation0['last_message']['text'] ).to eq 'finished'
        expect( conversation0['last_message']['status'] ).to eq 'finished'
      end
    end

    it 'should receive number of unread messages' do
      conv1 = FactoryGirl.create(:conversation, sender_id: user.id,
                                                initial: 'initial',
                                                reply: 'reply',
                                                finished: 'finished')
      conv2 = FactoryGirl.create(:conversation, receiver_id: user.id,
                                                initial: 'initial',
                                                reply: 'reply',
                                                finished: 'finished')

      conv1.reply_viewed = false
      conv1.finished_viewed = false
      conv1.save!
      conv2.reply_viewed = false
      conv2.finished_viewed = false
      conv2.save!
      post :unread_messages, authentication_token: auth_token
      expect( Oj.load(response.body)['success'] ).to be_truthy
      expect( Oj.load(response.body)['data'] ).to eq 3
    end

    it 'should remove conversation' do
      conversation = conv1 = FactoryGirl.create(:conversation, sender_id: user.id,
                                                initial: 'initial',
                                                reply: 'reply',
                                                finished: 'finished')
      post :remove_conversation, authentication_token: auth_token, conversation_id: conversation.id
      
      json = Oj.load(response.body)
      expect(json['success']).to be_truthy
      expect(json['info']).to match /Conversation removed/
      expect(json['status']).to eq 200

    end
  end

end
