require 'rails_helper'

describe Api::UsersController do

  it '#create' do
    expect{
      post :create, attributes_for(:user)
    }.to change(User, :count).by(1)
    expect( Oj.load(response.body)['success'] ).to eq true
  end

  describe 'with user' do


    it '#edit_profile' do
      attr = { first_name: 'X',
               last_name: 'Z',
               email: 'xz@mail.com',
               gender: 'Male',
               date_of_birth: 20.years.ago.strftime("%F"),
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

      it 'should send forgot password instructions' do
        user = create(:user_confirmed)
        post :forgot_password, email: user.email
        mail =  UserMailer.forgot_password(user, '12345').deliver
        expect(mail.subject).to match /New password for IceBr8kr account/
        expect(mail.to).to include(user.email)
      end
    end

    let(:user){ auth_user! }
    describe '#search' do
      render_views

      it 'should render json with data match location' do

        token1 = SecureRandom.hex(8)
        token2 = SecureRandom.hex(8)
        token3 = SecureRandom.hex(8)

        user_in_radius     = create(:user_confirmed)
        user_out_of_radius = create(:user_confirmed)
        user_in_radius2 = create(:user_confirmed)

        session1 = create(:session, user_id: user_in_radius.id, auth_token: token1, latitude: 40.7140, longitude: -74.0080)
        session2 = create(:session, user_id: user_out_of_radius.id, auth_token: token2, latitude: 40.7, longitude: -74.1)
        session3 = create(:session, user_id: user_in_radius2.id, auth_token: token3, latitude: 40.7140, longitude: -74.0080)

        post :search, authentication_token: token1, format: 'json'

        expect( assigns(:users_in_radius) ).to eq [user_in_radius2]
        expect( assigns(:users_out_of_radius) ).to eq [user_out_of_radius]

        expect( Oj.load(response.body)['users_in_radius'][0]['id'] ).to eq user_in_radius2.id
        expect( Oj.load(response.body)['users_out_of_radius'][0]['id'] ).to eq user_out_of_radius.id

      end
    end
  end

end
