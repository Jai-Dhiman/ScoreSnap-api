class OmrService
  def self.process_image(image_path)
    output_dir = Rails.root.join('tmp', 'omr_output')
    FileUtils.mkdir_p(output_dir)
    command = "oemer #{image_path}"
    
    begin
      system(command, chdir: output_dir)
      xml_file = Dir.glob(File.join(output_dir, '*.musicxml')).first
      
      if xml_file
        File.read(xml_file)
      else
        raise "OMR processing failed: No output file generated"
      end
    ensure
      FileUtils.rm_rf(output_dir)
    end
  end
end