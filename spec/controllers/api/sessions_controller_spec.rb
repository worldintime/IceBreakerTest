require 'rails_helper'

describe Api::SessionsController do

  describe 'session' do

    describe '#create' do
      it 'should create session' do
        user = create(:user)
        post :create, email: user.email, password: '123456789'
        expect( Oj.load(response.body)['success'] ).to eq true
      end

      it 'should create session and add device info' do
        user = create(:user)
        auth = {device: "iOS", device_token: '3n12j3khss'}
        post :create, email: user.email, password: '123456789', auth: auth
        user.reload
        session = user.sessions.first
        expect(session.device).to eq auth[:device]
        expect(session.device_token).to eq auth[:device_token]
        expect( Oj.load(response.body)['success'] ).to eq true
      end
    end

    describe '#destroy_sessions' do
      it 'should destroy' do
        user = create(:user, sessions: [ create(:session) ])
        expect_any_instance_of(Session).to receive(:destroy)
        post :destroy_sessions, authentication_token: user.sessions.first.auth_token
        expect( Oj.load(response.body)['success'] ).to eq true
      end

      it 'should return "Not Found" for invalid token' do
        delete :destroy_sessions, authentication_token: '12'
        expect( Oj.load(response.body)['info'] ).to match /Not Found/
      end
    end
  end
end
