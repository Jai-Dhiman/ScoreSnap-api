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

        output_filename = Thread.current[:mxl_filename] || "#{base_name}.mxl"
        send_processed_file(mxl_content, output_filename)
      rescue OmrService::OmrError => e
        Rails.logger.error("OMR Error: #{e.message}")
        render_error(e.message, :unprocessable_entity)
      rescue StandardError => e
        Rails.logger.error("Error processing file: #{e.message}\n#{e.backtrace.join("\n")}")
        render_error(e.message)
      ensure
        temp_file&.unlink
        Thread.current[:mxl_filename] = nil 
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
      render json: {
        error: message,
        details: {
          type: status,
          timestamp: Time.current,
          omr_errors: collect_omr_errors,
          suggestions: error_suggestions(status, message)
        }
      }, status: status
    end
    
    def collect_omr_errors
      {
        staff_errors: @staff_errors,
        barline_errors: @barline_errors,
        measure_errors: @measure_errors
      }
    end

    def error_suggestions(status, message)
      case status
      when :unprocessable_entity
        if message.include?('resolution')
          ["Scan the image at 300 DPI or higher", 
           "Use a flatbed scanner if possible",
           "Avoid taking photos with a phone camera"]
        elsif message.include?('contrast')
          ["Ensure good lighting when scanning",
           "Try adjusting the contrast before scanning",
           "Make sure the score is printed clearly on white paper"]
        else
          ["Ensure the image is clear and well-lit",
           "Check that the musical notation is standard",
           "Try scanning at 300 DPI or higher"]
        end
      when :bad_request
        ["Please select a file to upload",
         "Supported formats: JPG, PNG, PDF"]
      else
        ["Please try again",
         "If the problem persists, contact support"]
      end
    end
  end
end