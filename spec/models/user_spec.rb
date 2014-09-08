require 'rails_helper'
require 'spec_helper'



describe User do
  it 'should have validates' do
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
end
