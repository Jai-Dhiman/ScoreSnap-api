require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "POST /api/sessions" do
    it "creates a session and returns a JWT token" do
      post "/api/users.json", params: { name: "Test", email: "test@test.com", password: "password", password_confirmation: "password" }
      post "/api/sessions.json", params: { email: "test@test.com", password: "password" }
      
      expect(response).to have_http_status(201)
      
      data = JSON.parse(response.body)
      expect(data.keys).to match_array(["jwt", "email", "user_id"])
    end
  end
end
