require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  describe "POST #create" do
    it "creates a new user" do
      expect {
        post :create, params: {
  name: "Test",
  email: "test@test.com",
  password: "password",
  password_confirmation: "password"
}, format: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end