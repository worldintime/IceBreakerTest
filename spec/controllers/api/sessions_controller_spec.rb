require 'rails_helper'

describe Api::SessionsController do

  describe 'session' do

    describe '#create' do
      let(:auth){ {device: "iOS", device_token: '3n12j3khss'} }

      before :each do
        @user = create(:user_confirmed)
      end

      it 'should create session' do
        post :create, email: @user.email, password: '123456789'
        expect( Oj.load(response.body)['success'] ).to eq true
      end

      it 'should create session and add device info' do
        post :create, email: @user.email, password: '123456789', auth: auth
        @user.reload
        session = @user.sessions.first
        expect(session.device).to eq auth[:device]
        expect(session.device_token).to eq auth[:device_token]
        expect( Oj.load(response.body)['success'] ).to eq true
      end

      describe 'with invalid data' do
        it 'without confirmation' do
          @user.update(confirmed_at: nil)
          post :create, email: @user.email, password: '123456789', auth: auth
          expect( Oj.load(response.body)['errors'] ).to eq 'Please confirm your email first'
        end

        it 'without password' do
          post :create, email: @user.email, auth: auth
          expect( Oj.load(response.body)['errors'] ).to eq 'Email or password is incorrect!'
        end

        it 'without email' do
          post :create, auth: auth
          expect( Oj.load(response.body)['errors'] ).to eq 'User not found!'
        end
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
  end

  describe 'session filters' do
    it '#api_authenticate_user' do
      create(:session, auth_token: '123')
      delete :destroy, authentication_token: '123'
      expect(Oj.load(response.body)['info']).to eq "Session expired. Please login"
    end
  end

end
