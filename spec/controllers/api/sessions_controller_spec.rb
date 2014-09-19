require 'rails_helper'

describe Api::SessionsController do

  describe 'session' do
    it '#create' do
      user = create(:user)
      post :create, email: user.email, password: '123456789'
      expect( Oj.load(response.body)['success'] ).to eq true
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
        expect( Oj.load(response.body)['info'] ).to match /Not found/
      end
    end
  end

  describe '#reset_password' do
    before :each do
      ActionMailer::Base.deliveries.clear
    end

    it 'should send reset password instructions' do
      user = create(:user)
      post :reset_password, email: user.email
      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to match /Confirmation instructions/
      expect(mail.to).to include(user.email)
    end
  end
end
