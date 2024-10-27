class OmrService
  class OmrError < StandardError; end
  
  VALID_IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .pdf].freeze
  
  class << self
    def process_file(file_path)
      validate_file!(file_path)
      
      Rails.logger.info("OmrService processing file at path: #{file_path}")
      
      Dir.mktmpdir('omr_output') do |output_dir|
        image_path = prepare_image(file_path)
        process_with_audiveris(image_path, output_dir)
      end
    end

    private

    def validate_file!(file_path)
      extension = File.extname(file_path).downcase
      unless VALID_IMAGE_EXTENSIONS.include?(extension)
        raise OmrError, "Unsupported file format: #{extension}"
      end
    end

    def prepare_image(file_path)
      if File.extname(file_path).downcase == '.pdf'
        convert_pdf_to_image(file_path)
      else
        preprocess_image(file_path)
      end  
    end    

    def convert_pdf_to_image(pdf_path)
      image = MiniMagick::Image.new(pdf_path)
      image.format 'jpg'
      output_path = "#{pdf_path}.jpg"
      image.write output_path
      output_path
    end

    def preprocess_image(image_path)
      image = MiniMagick::Image.open(image_path)
      image.resize "2000x2000>"
      image.colorspace "Gray"
      image.contrast
      preprocessed_path = "#{image_path}_preprocessed.jpg"
      image.write preprocessed_path
      preprocessed_path
    end

    def process_with_audiveris(image_path, output_dir)
      command = build_audiveris_command(image_path, output_dir)
      stdout, stderr, status = Open3.capture3(command)
      
      log_audiveris_output(stdout, stderr)
      handle_audiveris_result(status, stderr, output_dir)
    end

    def build_audiveris_command(image_path, output_dir)
      script_path = Rails.root.join('lib', 'run_audiveris.sh')
      "bash #{script_path} -batch -export -output \"#{output_dir}\" -- \"#{image_path}\""
    end

    def log_audiveris_output(stdout, stderr)
      Rails.logger.info("Audiveris stdout: #{stdout}")
      Rails.logger.error("Audiveris stderr: #{stderr}") if stderr.present?
    end

    def handle_audiveris_result(status, stderr, output_dir)
      return find_and_read_mxl(output_dir) if status.success?
      
      raise OmrError, "Audiveris command failed: #{stderr}"
    end

    def find_and_read_mxl(output_dir)
      mxl_file = Dir.glob(File.join(output_dir, '*.mxl')).first
      return File.read(mxl_file) if mxl_file && File.size?(mxl_file)
      
      raise OmrError, "No valid .mxl file generated"
    end
  end  
end    