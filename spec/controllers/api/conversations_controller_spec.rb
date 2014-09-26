require 'rails_helper'

describe Api::ConversationsController do
  let(:user){ auth_user! }

  it '#messaging initial' do
    expect{
      post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1',
                       receiver_id: '2',type: 'initial', msg: 'initial'
    }.to change(Conversation, :count).by(1)
    expect( Oj.load(response.body)['success'] ).to eq true
  end

  describe 'conversation' do
    let(:user){ auth_user! }
    let(:conversation){ create(:conversation, id: id = rand(100))}

    it 'should receive reply' do
      post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1',
                       receiver_id: user.id, type: 'reply', msg: 'reply', conversation_id: conversation.id
        expect(conversation.reload.reply).to eq 'reply'
        expect(conversation.reload.status).to eq 'Closed'
    end

    it 'should receive last message' do
      expect{
        post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: user.id,
                         receiver_id: '1', type: 'finished', msg: 'finished', conversation_id: conversation.id
      }.to change(Mute, :count).by(1)

      conversation.reload
      expect(conversation.finished).to eq 'finished'
      expect(conversation.status).to eq 'Open'
    end

    it 'should ignore user' do
      expect{
        post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1',
                         receiver_id: '2', type: 'ignore', conversation_id: conversation.id
      }.to change(Mute, :count).by(1)

    end

    it 'should receive conversation detail' do

      post :conversation_detail, authentication_token: user.sessions.first.auth_token,
                                 conversation_id: conversation.id
      conversation.reload
      expect( Oj.load(response.body)['data']['opponent']['id'] ).to eq 1
    end

    it 'should receive conversation history' do

      post :history_of_digital_hello, authentication_token: user.sessions.first.auth_token
      conversation.reload
      expect( Oj.load(response.body)['success'] ).to eq true
    end

    it 'should receive number of unread messages' do

      post :unread_messages, authentication_token: user.sessions.first.auth_token
      conversation.reload
      expect( Oj.load(response.body)['success'] ).to eq true
      expect( Oj.load(response.body)['data'] ).to eq 3
    end

  end

end
