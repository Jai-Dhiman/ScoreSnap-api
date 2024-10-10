# app/services/omr_service.rb
require 'open3'
require 'mini_magick'

class OmrService
  class OmrError < StandardError; end

  def self.process_file(file_path)
    Rails.logger.info "OmrService processing file at path: #{file_path}"
    
    output_dir = Dir.mktmpdir('omr_output')
    
    begin
      if File.extname(file_path).downcase == '.pdf'
        image_path = convert_pdf_to_image(file_path)
      else
        image_path = preprocess_image(file_path)
      end

      mxl_content = run_omr(image_path, output_dir)
      
      if mxl_content.nil? || mxl_content.empty?
        raise OmrError, "OMR processing failed: No valid MusicXML content generated"
      end
      
      mxl_content
    ensure
      FileUtils.remove_entry(output_dir)
    end
  end

  private

  def self.convert_pdf_to_image(pdf_path)
    image = MiniMagick::Image.new(pdf_path)
    image.format 'jpg'
    image.write "#{pdf_path}.jpg"
    "#{pdf_path}.jpg"
  end

  def self.preprocess_image(image_path)
    image = MiniMagick::Image.open(image_path)
    image.resize "2000x2000>"
    image.colorspace "Gray"
    image.contrast
    preprocessed_path = "#{image_path}_preprocessed.jpg"
    image.write preprocessed_path
    preprocessed_path
  end

  def self.run_omr(image_path, output_dir)
    audiveris_script = Rails.root.join('lib', 'run_audiveris.sh')
    command = "bash #{audiveris_script} -batch -export -output \"#{output_dir}\" -- \"#{image_path}\""
    
    stdout, stderr, status = Open3.capture3(command)
    
    Rails.logger.info "Audiveris stdout: #{stdout}"
    Rails.logger.error "Audiveris stderr: #{stderr}" if stderr.present?
    
    if status.success?
      mxl_file = Dir.glob(File.join(output_dir, '*.mxl')).first
      if mxl_file && File.size?(mxl_file)
        File.read(mxl_file)
      else
        raise OmrError, "OMR processing failed: No valid .mxl file generated"
      end
    else
      raise OmrError, "Audiveris command failed: #{stderr}"
    end
  end
end