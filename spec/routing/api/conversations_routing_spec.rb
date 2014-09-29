require "spec_helper"

describe Api::ConversationsController do
  describe "routing" do

    it "routes to #messaging" do
      expect( post("api/messaging") ).to route_to("api/conversations#messaging", format: 'json')
    end
  end
end
