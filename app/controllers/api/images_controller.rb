module Api
  class ImagesController < ApplicationController
    def process_image
      Rails.logger.debug "Process method called"
      Rails.logger.debug "Params: #{params.inspect}"
      Rails.logger.debug "Request content type: #{request.content_type}"
      
      file = params[:file]
      Rails.logger.debug "File present: #{file.present?}"
      
      if file.present?
        Rails.logger.debug "File details: #{file.inspect}"
        begin
          original_filename = file.original_filename
          Rails.logger.debug "Original filename: #{original_filename}"
          
          extension = File.extname(original_filename)
          base_name = File.basename(original_filename, extension)
          Rails.logger.debug "Extension: #{extension}, Base name: #{base_name}"
          
          temp_file = store_temp_file(file)
          Rails.logger.debug "Temp file created: #{temp_file.path}"
          
          mxl_content = OmrService.process_file(temp_file.path)
          Rails.logger.debug "MXL content generated, length: #{mxl_content&.length}"
          
          mxl_filename = "#{base_name}.mxl"

          Rails.logger.debug "mxl_filename: #{mxl_filename.inspect}"
          Rails.logger.debug "mxl_content length: #{mxl_content.length}"
          Rails.logger.debug "Locale: #{I18n.locale}"
          Rails.logger.debug "Available locales: #{I18n.available_locales}"
          Rails.logger.debug "Default locale: #{I18n.default_locale}"
          send_data mxl_content,
                    type: 'application/vnd.recordare.musicxml+xml',
                    disposition: "attachment; filename=\"#{mxl_filename}\"".force_encoding('ASCII-8BIT')
        rescue => e
          Rails.logger.error "Error processing file: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: e.message }, status: :internal_server_error
        ensure
          temp_file.unlink if temp_file
        end
      else
        Rails.logger.warn "No file provided in the request"
        render json: { error: 'No file provided' }, status: :bad_request
      end
    end

    private

    def store_temp_file(file)
      temp_file = Tempfile.new(['upload', File.extname(file.original_filename)])
      temp_file.binmode
      temp_file.write(file.read)
      temp_file.close
      Rails.logger.debug "Temp file stored: #{temp_file.path}"
      temp_file
    end
  end
end