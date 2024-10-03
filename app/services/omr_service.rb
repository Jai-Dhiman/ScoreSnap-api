# app/services/omr_service.rb
class OmrService
  def self.process_image(image_path)
    output_dir = Rails.root.join('tmp', 'omr_output')
    FileUtils.mkdir_p(output_dir)

    command = "oemer #{image_path}"
    system(command, chdir: output_dir)

    # Assuming oemer outputs a MusicXML file with the same name as the input image
    xml_file = Dir.glob(File.join(output_dir, '*.musicxml')).first
    
    if xml_file
      File.read(xml_file)
    else
      raise "OMR processing failed"
    end
  end
end