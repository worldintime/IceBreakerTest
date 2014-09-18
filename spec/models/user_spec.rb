require 'rails_helper'
require 'support/omniauth_mock'

describe User do
  it 'should validate' do
    validate_uniqueness_of :email
    validate_presence_of :user_name
    validate_presence_of :email
    validate_presence_of :first_name
    validate_presence_of :last_name
    validate_presence_of :gender
    validate_presence_of :date_of_birth
  end

  it 'should create user' do
    user = build :user
    expect(user.save).to be true
  end

  describe 'oauth' do
    describe 'facebook' do
      it 'should create user' do
        expect{
          described_class.from_omniauth OmniauthMock.facebook
        }.to change(User, :count).by(1)
      end

      it 'should update user' do
        auth = OmniauthMock.facebook
        user = create(:user, facebook_id: auth.extra.raw_info.id)
        described_class.from_omniauth auth
        user.reload
        expect(user.first_name).to eq auth.info.first_name
        expect(user.last_name).to eq auth.info.last_name
        expect(user.oauth_token).to eq auth.credentials.token
        expect(user.oauth_expires_at).to eq Time.at(auth.credentials.expires_at)
        expect(user.email).to eq auth.info.email
        expect(user.date_of_birth).to eq Date.strptime(auth.extra.raw_info.birthday, "%m/%d/%Y")
        expect(user.gender).to eq auth.extra.raw_info.gender
      end
    end
  end
end
