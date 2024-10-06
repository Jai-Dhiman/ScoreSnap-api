require 'open3'
require 'mini_magick'

class OmrService
  class OmrError < StandardError; end

  def self.process_image(image_path)
    Rails.logger.info "OmrService processing image at path: #{image_path}"
    Rails.logger.info "File exists: #{File.exist?(image_path)}"
    Rails.logger.info "File readable: #{File.readable?(image_path)}"
  
    output_dir = Rails.root.join('tmp', 'omr_output')
    FileUtils.mkdir_p(output_dir)
  
    begin
      preprocessed_image = preprocess_image(image_path)
      mxl_content = run_omr(preprocessed_image, output_dir)
      
      # You might want to save or process the MusicXML content here
      # For now, we'll just return it
      mxl_content
    ensure
      FileUtils.rm_rf(output_dir)
    end
  end
  private

  def self.preprocess_image(image_path)
    Rails.logger.info "Preprocessing image: #{image_path}"
    image = MiniMagick::Image.open(image_path)

    Rails.logger.info "Resizing image"
    image.resize "2000x2000>"

    Rails.logger.info "Converting to grayscale"
    image.colorspace "Gray"

    Rails.logger.info "Increasing contrast"
    image.contrast

    preprocessed_path = File.join(File.dirname(image_path), "preprocessed_#{File.basename(image_path)}")
    image.write preprocessed_path
    Rails.logger.info "Preprocessed image saved to: #{preprocessed_path}"

    preprocessed_path
  end

  def self.run_omr(image_path, output_dir)
    audiveris_script = Rails.root.join('lib', 'run_audiveris.sh')
    FileUtils.mkdir_p(output_dir)
    command = "bash #{audiveris_script} -batch -export -output \"#{output_dir}\" -- \"#{image_path}\""
    Rails.logger.info "Running OMR command: #{command}"
    
    stdout, stderr, status = Open3.capture3(command)
    
    Rails.logger.info "Audiveris stdout: #{stdout}"
    Rails.logger.error "Audiveris stderr: #{stderr}" if stderr.present?
    
    if status.success?
      mxl_file = Dir.glob(File.join(output_dir, '*.mxl')).first
      if mxl_file && File.size?(mxl_file)
        Rails.logger.info "Found MusicXML file: #{mxl_file}"
        return File.read(mxl_file)
      else
        Rails.logger.error "OMR processing failed: No valid .mxl file generated"
        Rails.logger.error "Output directory contents: #{Dir.entries(output_dir)}"
        raise OmrError, "OMR processing failed: No valid .mxl file generated"
      end
    else
      Rails.logger.error "Audiveris command failed with status: #{status.exitstatus}"
      raise OmrError, "Audiveris command failed: #{stderr}"
    end
  end

  def self.validate_musicxml(xml_content)
    doc = Nokogiri::XML(xml_content) { |config| config.strict }
    Rails.logger.info "MusicXML validation successful"
  rescue Nokogiri::XML::SyntaxError => e
    Rails.logger.error "Invalid MusicXML: #{e.message}"
    raise OmrError, "Invalid MusicXML generated: #{e.message}"
  end
end