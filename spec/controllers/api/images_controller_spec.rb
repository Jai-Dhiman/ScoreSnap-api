require 'rails_helper'

RSpec.describe Api::ImagesController, type: :controller do
  describe "POST #upload" do
    it "returns a success response" do
      post :upload, params: { image: fixture_file_upload('spec/fixtures/files/test_text.txt', 'text/txt') }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['status']).to eq('success')
      expect(JSON.parse(response.body)['image_path']).to be_present
    end

    it "returns an error if no image is provided" do
      post :upload
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST #process" do
    it "processes an image successfully" do
      allow(OmrService).to receive(:process_image).and_return("<score></score>")
      post :process, params: { image_path: '/path/to/image.png' }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['status']).to eq('success')
    end

    it "returns an error if processing fails" do
      allow(OmrService).to receive(:process_image).and_raise(StandardError.new("Processing failed"))
      post :process, params: { image_path: '/path/to/image.png' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['status']).to eq('error')
    end

    it "returns an error if no image path is provided" do
      post :process
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['status']).to eq('error')
    end
  end
end