require 'fileutils'

module Api
  class ImagesController < ApiController
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
          mxl_content = OmrService.process_image(image_path)
          
          scores_dir = Rails.root.join('public', 'scores')
          FileUtils.mkdir_p(scores_dir)
          
          file_name = "score_#{Time.now.to_i}.mxl"
          file_path = File.join(scores_dir, file_name)
          File.open(file_path, 'wb') do |file|
            file.write(mxl_content)
          end
          
          score = Score.new(file_path: "/scores/#{file_name}")
          if score.save
            render json: { status: 'success', score_id: score.id, file_path: "/scores/#{file_name}" }, status: :created
          else
            render json: { status: 'error', message: score.errors.full_messages }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error "Error processing image: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { status: 'error', message: e.message }, status: :internal_server_error
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