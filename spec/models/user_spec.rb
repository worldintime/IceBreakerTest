require 'rails_helper'

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

  it 'should add address by location data' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    expect( user.address ).to match /NY/
  end
end
