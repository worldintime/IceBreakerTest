require 'rails_helper'

describe Api::UsersController do
  context "POST create" do
    let(:users_params) {attributes_for :user }

    it 'success' do
      expect {
        post :create, users_params
      }.to change{ User.count }.by(1)

      expect(response.status).to eq(200)
    end
  end

end
