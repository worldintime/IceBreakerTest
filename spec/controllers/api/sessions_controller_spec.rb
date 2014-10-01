require 'rails_helper'

describe Api::SessionsController do

  describe 'session' do

    describe '#create' do
      it 'should create session' do
        user = create(:user_confirmed)
        post :create, email: user.email, password: '123456789'
        expect( Oj.load(response.body)['success'] ).to eq true
      end

      it 'should create session and add device info' do
        user = create(:user_confirmed)
        auth = {device: "iOS", device_token: '3n12j3khss'}
        post :create, email: user.email, password: '123456789', auth: auth
        user.reload
        session = user.sessions.first
        expect(session.device).to eq auth[:device]
        expect(session.device_token).to eq auth[:device_token]
        expect( Oj.load(response.body)['success'] ).to eq true
      end
    end

    describe '#destroy' do
      it 'should destroy' do
        user = create(:user, sessions: [ create(:session) ])
        expect_any_instance_of(Session).to receive(:destroy)
        delete :destroy, authentication_token: user.sessions.first.auth_token
        expect( Oj.load(response.body)['success'] ).to eq true
      end

      it 'should return "Not Found" for invalid token' do
        delete :destroy, authentication_token: '12'
        expect( Oj.load(response.body)['info'] ).to match /Session expired. Please login/
      end
    end

    let(:user){ auth_user! }
    let(:session){ create( :session, latitude: '20,15', longitude: 24.33 )}
    describe '#location' do
      it '#set_location' do
        loc = { latitude: '20,15', longitude: 24.33 }

        post :set_location, authentication_token: user.sessions.first.auth_token, location: loc
        session.reload
        expect(session.latitude).to eq loc[:latitude].to_f
        expect(session.longitude).to eq loc[:longitude]
      end

      it '#reset_location' do
        token = SecureRandom.hex(8)
        session2 = create( :session, user_id: user.id, latitude: '12.12', longitude: '12.43',
                           auth_token: token )
        post :reset_location, authentication_token: token
        session2.reload
        expect(session2.latitude).to eq nil
        expect(session2.longitude).to eq nil
      end
    end
  end

end
