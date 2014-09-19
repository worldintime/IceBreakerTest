require 'rails_helper'

describe Api::UsersController do

  it '#create' do
    expect{
      post :create, attributes_for(:user)
    }.to change(User, :count).by(1)
    expect( Oj.load(response.body)['success'] ).to eq true
  end

  describe 'with user' do
    let(:user){ auth_user! }

    it '#edit_profile' do
      attr = { first_name: 'X',
               last_name: 'Z',
               email: 'xz@mail.com',
               gender: 'Male',
               date_of_birth: 20.years.ago.to_s,
               user_name: 'x_Z',
               avatar: fixture_file_upload('files/photo.jpg', 'image/jpg') }

      post :edit_profile, authentication_token: user.sessions.first.auth_token, user: attr

      user.reload
      expect(user.first_name).to eq attr[:first_name]
      expect(user.last_name).to eq attr[:last_name]
      expect(user.unconfirmed_email).to eq attr[:email] # need email confirm when update
      expect(user.gender).to eq attr[:gender]
      expect(user.date_of_birth.to_s).to eq attr[:date_of_birth]
      expect(user.user_name).to eq attr[:user_name]
      expect(user.avatar.url).to match /photo\.jpg/
    end

    describe '#forgot_password' do
      before :each do
        ActionMailer::Base.deliveries.clear
      end

      it 'should send email wit instructions' do
        post :forgot_password, email: user.email
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to).to include(user.email)
      end
    end

    describe '#search' do
      render_views

      it 'should render json with data match location' do
        create(:user, latitude: 40.7140, longitude: -74.0080)
        expected_user = create(:user, latitude: 40.7130, longitude: -74.0070)
        user.update_attributes!(latitude: 40.7127, longitude: -74.0059)
        post :search, authentication_token: user.sessions.first.auth_token, format: 'json'
        expect( assigns(:designated_users) ).to eq [expected_user]
        expect( Oj.load(response.body)['designated_users'][0]['id'] ).to eq expected_user.id
      end
    end

    it '#location' do
      loc = {latitude: '20,15', longitude: 24.33}
      post :location, authentication_token: user.sessions.first.auth_token, location: loc
      user.reload
      expect(user.latitude).to eq 20.15
      expect(user.longitude).to eq 24.33
    end
  end
end
