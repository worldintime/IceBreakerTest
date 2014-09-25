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

    describe '#search' do
      render_views

      it 'should render json with data match location' do
        user_in_radius     = create(:user_confirmed, latitude: 40.7140, longitude: -74.0080)
        user_out_of_radius = create(:user_confirmed, latitude: 40.7, longitude: -74.1)
        post :search, authentication_token: user.sessions.first.auth_token, format: 'json'

        expect( assigns(:users_in_radius) ).to eq [user_in_radius]
        expect( assigns(:users_out_of_radius) ).to eq [user_out_of_radius]
        expect( Oj.load(response.body)['users_in_radius'][0]['id'] ).to eq user_in_radius.id
        expect( Oj.load(response.body)['users_out_of_radius'][0]['id'] ).to eq user_out_of_radius.id
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
