require 'rails_helper'

describe Api::UsersController do

  it '#create' do
    expect{
      post :create, attributes_for(:user)
    }.to change(User, :count).by(1)
    expect( Oj.load(response.body)['success'] ).to be_truthy
  end

  describe 'with user' do
    let(:user){ auth_user! }
    let(:auth_token){ user.sessions.first.auth_token }

    it '#edit_profile' do
      attr = { first_name: 'X',
               last_name: 'Z',
               email: 'xz@mail.com',
               gender: 'Male',
               date_of_birth: 20.years.ago.strftime("%F"),
               user_name: 'x_z',
               avatar: fixture_file_upload('files/photo.jpg', 'image/jpg') }

      post :edit_profile, authentication_token: auth_token, user: attr

      user.reload
      expect(user.first_name).to eq attr[:first_name]
      expect(user.last_name).to eq attr[:last_name]
      expect(user.unconfirmed_email).to eq attr[:email] # need email confirm when update
      expect(user.gender).to eq attr[:gender]
      expect(user.date_of_birth.to_s).to eq attr[:date_of_birth]
      expect(user.user_name).to eq attr[:user_name]
      expect(user.avatar.url).to match /photo\.jpg/
    end

    it '#set_location' do
      user2 = FactoryGirl.create(:user, latitude: 20.15, longitude: 24.33 )
      PendingConversation.create(sender_id: user.id, receiver_id: user2.id, conversation_id: 1)
      loc = {latitude: '20,15', longitude: 24.33}
      expect{
        post :set_location, authentication_token: auth_token, location: loc
      }.to change(PendingConversation, :count).by(-1)
      user.reload
      expect(user.latitude).to eq 20.15
      expect(user.longitude).to eq 24.33
    end

    it '#reset_location' do
      post :reset_location, authentication_token: auth_token
      user.reload
      expect(user.latitude).to be_nil
      expect(user.longitude).to be_nil
    end

    describe '#forgot_password' do
      before :each do
        ActionMailer::Base.deliveries.clear
      end

      it 'should send forgot password instructions' do
        post :forgot_password, email: user.email
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match /New password for IceBr8kr account/
        expect(mail.to).to include(user.email)
      end
    end

    describe 'json view' do
      render_views

      describe '#search' do
        it 'should render json with data match location' do
          user_in_radius     = create(:user_confirmed, latitude: 40.7140, longitude: -74.0080)
          user_out_of_radius = create(:user_confirmed, latitude: 40.7, longitude: -74.1)
          post :search, authentication_token: auth_token, format: 'json'

          expect( assigns(:users_in_radius) ).to eq [user_in_radius]
          expect( assigns(:users_out_of_radius) ).to eq [user_out_of_radius]
          json = Oj.load(response.body)
          expect( json['users_in_radius'][0]['id'] ).to eq user_in_radius.id
          expect( json['users_out_of_radius'][0]['id'] ).to eq user_out_of_radius.id
        end
      end

      it '#canned_statements' do
        c_s = CannedStatement.create(user_id: user.id, body: 'X')
        post :canned_statements, authentication_token: auth_token, format: 'json'
        canned_statements = Oj.load(response.body)['canned_statements'][0]
        expect(canned_statements['id']).to eq c_s.id
        expect(canned_statements['body']).to eq c_s.body
      end
    end

    describe '#upload_avatar' do
      before :each do
        avatar = fixture_file_upload('files/photo.jpg', 'image/jpg')
        @params = { authentication_token: auth_token,
                    email: user.email,
                    avatar: avatar,
                    format: 'json' }
      end

      %w(OPTIONS).each do |method|
        it "via #{method}" do
          process(:upload_avatar, method, @params)
          user.reload
          expect(user.avatar_file_name).to eq 'photo.jpg'
          expect(Oj.load(response.body)['info']).to match /Image successfully uploaded/
        end
      end
    end
  end

end
