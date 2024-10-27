module Api
  class ImagesController < ApplicationController
    def process_image
      return render_error('No file provided', :bad_request) unless params[:file].present?
      
      begin
        file = params[:file]
        original_filename = file.original_filename
        extension = File.extname(original_filename)
        base_name = File.basename(original_filename, extension)
        
        temp_file = store_temp_file(file)
        mxl_content = OmrService.process_file(temp_file.path)
        
        send_processed_file(mxl_content, "#{base_name}.mxl")
      rescue StandardError => e
        Rails.logger.error("Error processing file: #{e.message}\n#{e.backtrace.join("\n")}")
        render_error(e.message)
      ensure
        temp_file&.unlink
      end
    end

    private

    def store_temp_file(file)
      temp_file = Tempfile.new(['upload', File.extname(file.original_filename)])
      temp_file.binmode
      temp_file.write(file.read)
      temp_file.close
      temp_file
    end

    def send_processed_file(content, filename)
      send_data content,
                type: 'application/vnd.recordare.musicxml+xml',
                disposition: "attachment; filename=\"#{filename}\"".force_encoding('ASCII-8BIT')
    end

    def render_error(message, status = :internal_server_error)
      render json: { error: message }, status: status
    end
  end
end