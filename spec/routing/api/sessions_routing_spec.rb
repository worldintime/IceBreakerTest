require "spec_helper"

describe Api::SessionsController do
  describe "routing" do

    it "routes to #create" do
      expect( post("api/sessions") ).to route_to("api/sessions#create", format: 'json')
    end

    it "routes to #destroy" do
      expect( post("api/destroy_sessions") ).to route_to("api/sessions#destroy", format: 'json')
    end

    it "routes to #set_location" do
      expect( post("api/set_location") ).to route_to("api/sessions#set_location", format: 'json')
    end

    it "routes to #reset_location" do
      expect( post("api/reset_location") ).to route_to("api/sessions#reset_location", format: 'json')
    end

  end
end
