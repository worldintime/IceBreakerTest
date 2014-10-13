require 'rails_helper'

RSpec.describe Session, :type => :model do
  before :each do
    user = create(:user_confirmed)
    @session = described_class.create(user_id: user.id, auth_token: SecureRandom.hex , updated_at: Time.now)
  end

  it 'should create session' do
    expect(described_class.first).to eq @session
  end

  it 'should destroy session' do
    @session.destroy
    expect(described_class.all.to_a).to be_empty
  end
end
