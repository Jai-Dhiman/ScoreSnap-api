module Api
  class ImagesController < ApplicationController
    def upload
      image = params[:image]
      if image.present?
        image_path = store_image(image)
        render json: { status: 'success', image_path: image_path }, status: :ok
      else
        render json: { status: 'error', message: 'No image provided' }, status: :bad_request
      end
    end

    def process_image
      image_path = params[:image_path]
      if image_path.present?
        begin
          musicxml = OmrService.process_image(image_path)
          score = Score.create!(xml_data: musicxml)
          render json: { status: 'success', score_id: score.id }, status: :created
        rescue StandardError => e
          render json: { status: 'error', message: e.message }, status: :unprocessable_entity
        end
      else
        render json: { status: 'error', message: 'No image path provided' }, status: :bad_request
      end
    end

    private

    def store_image(image)
      temp_file = Tempfile.new(['image', File.extname(image.original_filename)])
      temp_file.binmode
      temp_file.write(image.read)
      temp_file.close
      # In a real application, you'd move this file to a permanent location
      # and return a path or ID that can be used to retrieve it later
      temp_file.path
    end
  end
end