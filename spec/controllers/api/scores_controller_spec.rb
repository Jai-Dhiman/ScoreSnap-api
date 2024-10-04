require 'rails_helper'

RSpec.describe Api::ScoresController, type: :controller do
  let(:valid_attributes) { { xml_data: "<score><measure></measure></score>" } }
  let(:invalid_attributes) { { xml_data: nil } }
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      Score.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      score = Score.create! valid_attributes
      get :show, params: {id: score.to_param}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { xml_data: "<score><measure><note></note></measure></score>" } }

      it "updates the requested score" do
        score = Score.create! valid_attributes
        put :update, params: {id: score.to_param, score: new_attributes}, session: valid_session
        score.reload
        expect(score.xml_data).to eq(new_attributes[:xml_data])
      end
    end

    context "with invalid params" do
      it "returns a error response" do
        score = Score.create! valid_attributes
        put :update, params: {id: score.to_param, score: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested score" do
      score = Score.create! valid_attributes
      expect {
        delete :destroy, params: {id: score.to_param}, session: valid_session
      }.to change(Score, :count).by(-1)
    end
  end
end