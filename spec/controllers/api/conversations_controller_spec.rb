require 'rails_helper'

describe Api::ConversationsController do

  let(:user){ auth_user! }
  it '#messaging initial' do
    expect{
      post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1', receiver_id: '2',type: 'initial', msg: 'initial'
    }.to change(Conversation, :count).by(1)
    expect( Oj.load(response.body)['success'] ).to eq true
  end

  it '#messaging reply' do
    id = rand(100)
    @conv = FactoryGirl.create :conversation, id: id, sender_id: '1', receiver_id: '2', initial: 'initial', reply: nil
    post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1',
                       receiver_id: '2',type: 'reply', msg: 'reply', conversation_id: id

      expect(@conv.reload.reply).to eq 'reply'
  end

  it '#messaging finished' do
    id = rand(100)
    @conv = FactoryGirl.create :conversation, id: id, sender_id: '1', receiver_id: '2', initial: 'initial', reply: nil,
                               finished: nil
    expect{
      post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1',
            receiver_id: '2',type: 'finished', msg: 'finished', conversation_id: id
    }.to change(Mute, :count).by(1)

    expect(@conv.reload.finished).to eq 'finished'
  end

  it '#messaging ignore' do
    id = rand(100)
    @conv = FactoryGirl.create :conversation, id: id, sender_id: id, receiver_id: '2', initial: 'initial', reply: nil,
                               finished: nil
    expect{
      post :messaging, authentication_token: user.sessions.first.auth_token, sender_id: '1',
           receiver_id: '2',type: 'ignore', conversation_id: id
    }.to change(Mute, :count).by(1)
  end

end
