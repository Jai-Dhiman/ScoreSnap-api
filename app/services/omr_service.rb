class OmrService
  class OmrError < StandardError; end
  
  VALID_IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .pdf].freeze
  
  class << self
    def process_file(file_path)
      validate_file!(file_path)
      
      Rails.logger.info("OmrService processing file at path: #{file_path}")
      
      Dir.mktmpdir('omr_output') do |output_dir|
        image_path = prepare_image(file_path)
        check_converted_image_quality!(image_path) if File.extname(file_path).downcase == '.pdf'
        process_with_audiveris(image_path, output_dir)
      end
    end

    private

    def validate_file!(file_path)
      extension = File.extname(file_path).downcase
      unless VALID_IMAGE_EXTENSIONS.include?(extension)
        raise OmrError, "Unsupported file format: #{extension}"
      end
      
      check_file_quality!(file_path) unless extension == '.pdf'
    end

    def check_file_quality!(file_path)
      image = MiniMagick::Image.open(file_path)
      config = Rails.application.config.x.omr
      
      if image.resolution && image.resolution[0]
        if image.resolution[0] < config[:min_image_quality]
          raise OmrError, "Image resolution too low. Please provide an image of at least #{config[:min_image_quality]} DPI"
        end
      end

      check_dimensions!(image)

      begin
        identify_output = image.identify
        mean = identify_output[/mean:(.*?)\s/,1].to_f
        std_dev = identify_output[/standard deviation:(.*?)\s/,1].to_f
        
        if std_dev < config[:min_contrast]
          raise OmrError, "Image contrast too low. Please provide a clearer image"
        end
      rescue => e
        Rails.logger.warn("Could not check image contrast: #{e.message}")
      end

      check_file_size!(file_path)
    end

    def check_converted_image_quality!(image_path)
      image = MiniMagick::Image.open(image_path)
      check_dimensions!(image)
      check_file_size!(image_path)
    end

    def check_dimensions!(image)
      config = Rails.application.config.x.omr
      if image.width < config[:min_width] || image.height < config[:min_height]
        raise OmrError, "Image dimensions too small. Minimum size is #{config[:min_width]}x#{config[:min_height]} pixels"
      end
    end

    def check_file_size!(file_path)
      config = Rails.application.config.x.omr
      if File.size(file_path) > config[:max_file_size]
        raise OmrError, "File too large. Maximum size is #{config[:max_file_size] / 1.megabyte}MB"
      end
    end

    def validate_and_fix_image!(image_path)
      image = MiniMagick::Image.open(image_path)
      
      fixed = false
      
      skew = `convert #{image_path} -background white -deskew 40% /dev/null 2>&1`
      if skew.include?("skew:") && skew.split("skew:")[1].to_f.abs > 0.1
        image.deskew '40%'
        fixed = true
      end
      
      identify = image.identify
      mean = identify[/mean:(.*?)\s/,1].to_f
      std_dev = identify[/standard deviation:(.*?)\s/,1].to_f
      
      if std_dev < 20 
        image.contrast
        image.contrast
        fixed = true
      end
      
      if fixed
        image.write image_path
      end
      
      image_path
    end

    def prepare_image(file_path)
      if File.extname(file_path).downcase == '.pdf'
        image_path = convert_pdf_to_image(file_path)
        validate_and_fix_image!(image_path)
        enhance_staff_lines(image_path)
      else
        validate_and_fix_image!(file_path)
        preprocess_image(file_path)
      end
    end 

    def convert_pdf_to_image(pdf_path)
      output_base = pdf_path.sub('.pdf', '')
      output_path = "#{output_base}.jpg"
      
      pdftoppm_cmd = [
        "pdftoppm",
        "-r", "300", 
        "-jpeg",
        "-singlefile",
        "-gray",
        pdf_path,
        output_base
      ].join(" ")
      
      system(pdftoppm_cmd)
      
      unless File.exist?(output_path)
        raise OmrError, "Failed to convert PDF to image"
      end
      
      # Minimal preprocessing for PDF
      image = MiniMagick::Image.open(output_path)
      image.combine_options do |cmd|
        cmd.resize "2000x2000>" 
        cmd.sharpen "0x0.5" 
      end
      image.write output_path
      
      Rails.logger.info("Converted PDF to image: #{image.width}x#{image.height} pixels")
      
      output_path
    end

    def enhance_staff_lines(image_path)
      image = MiniMagick::Image.open(image_path)
      
      image.combine_options do |cmd|
        cmd.colorspace 'gray'
        cmd.auto_level
        cmd.contrast
        cmd.level '25%,75%' 
      end
      
      image.combine_options do |cmd|
        cmd.unsharp '2x0.5+0.5+0'
        cmd.normalize
      end
      
      enhanced_path = "#{image_path}_enhanced.jpg"
      image.write enhanced_path
      enhanced_path
    end

    def preprocess_image(image_path)
      image = MiniMagick::Image.open(image_path)
      image.resize "2000x2000>"
      image.colorspace "Gray"
      image.contrast
      image.enhance
      image.sharpen
      
      preprocessed_path = "#{image_path}_preprocessed.jpg"
      image.write preprocessed_path
      enhance_staff_lines(preprocessed_path)
    end 

    def validate_staff_barlines!(output_dir)
      book_xml = File.join(output_dir, 'book.xml')
      return unless File.exist?(book_xml)
    
      doc = Nokogiri::XML(File.read(book_xml))
      staff_nodes = doc.xpath('//staff')
      
      staff_nodes.each do |staff|
        barlines = staff.xpath('.//barline')
        if barlines.empty?
          raise OmrError, "Missing barlines in staff - poor image quality or staff line detection"
        end
      end
    end
    
    def process_with_audiveris(image_path, output_dir, retry_count = 0)
      return nil if retry_count > 2  
      
      begin
        validate_and_fix_image!(image_path)
        enhanced_image = enhance_staff_lines(image_path)
        command = build_audiveris_command(enhanced_image, output_dir)
        stdout, stderr, status = Open3.capture3(command)
        
        log_audiveris_output(stdout, stderr)
        
        if stderr.include?("PartBarline with no proper StaffBarline") ||
           stderr.include?("no header clef") ||
           stderr.include?("No target duration for measures")
          
          if retry_count == 0
            image = MiniMagick::Image.open(image_path)
            image.morphology 'close', 'horizontal:3'
            image.write image_path
          elsif retry_count == 1
            image = MiniMagick::Image.open(image_path)
            image.gaussian_blur '0x0.5'
            image.sharpen
            image.write image_path
          end
          
          return process_with_audiveris(image_path, output_dir, retry_count + 1)
        end
        
        handle_audiveris_result(status, stderr, output_dir)
        
      rescue => e
        Rails.logger.error("Audiveris processing error: #{e.message}")
        raise OmrError, "Failed to process score: #{e.message}"
      end
    end

    def build_audiveris_command(image_path, output_dir)
      script_path = Rails.root.join('lib', 'run_audiveris.sh')
      [
        "bash #{script_path}",
        "-batch",
        "-export",
        "-option", "interline.min=8",
        "-option", "interline.max=200",
        "-option", "scale.minInterline=8",
        "-option", "scale.maxInterline=200",
        "-option", "staff.minStaffLength=0.2",
        "-option", "sheet.scale.plotting=true",  
        "-option", "default.interline=16",       
        "-option", "filter.scale.maxCount=10",
        "-option", "staff.line.detection=true",
        "-option", "measure.minWidth=20",
        "-option", "clef.minGrade=0.3",  
        "-option", "note.grace.maxStemLength=6.0",
        "-option", "note.grace.stemLengthRange=4.0",
        "-option", "note.small.maxStemLength=6.0",
        "-option", "note.small.stemLengthRange=4.0",
        "-option", "staff.smallStaffLineThickness=1.5",
        "-option", "staff.smallStaffScale=0.67",
        "-output", "\"#{output_dir}\"",
        "--",
        "\"#{image_path}\""
      ].join(" ")
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