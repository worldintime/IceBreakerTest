require 'rails_helper'

RSpec.describe Session, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"


  it 'should add address by location data' do
    session = create(:session, latitude: 40.7127, longitude: -74.0059)
    expect( session.address ).to match /NY/
  end

end
