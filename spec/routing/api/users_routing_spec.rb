require "spec_helper"

describe Api::UsersController do
  describe "routing" do

    it "routes to #create" do
      expect( post("api/users") ).to route_to("api/users#create", format: 'json')
    end

    it "routes to #search" do
      expect( post("api/search") ).to route_to("api/users#search", format: 'json')
    end

    it "routes to #set_location" do
      expect( post("api/set_location") ).to route_to("api/users#set_location", format: 'json')
    end

    it "routes to #edit_profile" do
      expect( post("api/edit_profile") ).to route_to("api/users#edit_profile", format: 'json')
    end

  end
end
