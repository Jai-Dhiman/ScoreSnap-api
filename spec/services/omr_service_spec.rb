require 'rails_helper'

RSpec.describe OmrService do
  describe ".process_image" do
    it "processes an image and returns XML data" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Image).to receive(:open).and_return(double(resize: nil, colorspace: nil, contrast: nil, adaptive_threshold: nil, write: nil))
      allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
      allow(Dir).to receive(:glob).and_return(['/path/to/output.musicxml'])
      allow(File).to receive(:read).and_return("<score></score>")
      
      result = OmrService.process_image('/path/to/image.png')
      expect(result).to eq("<score></score>")
    end

    it "raises an error when processing fails due to no output file" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Image).to receive(:open).and_return(double(resize: nil, colorspace: nil, contrast: nil, adaptive_threshold: nil, write: nil))
      allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
      allow(Dir).to receive(:glob).and_return([])
      
      expect {
        OmrService.process_image('/path/to/image.png')
      }.to raise_error(OmrService::OmrError, "OMR processing failed: No output file generated")
    end

    it "raises an error when OMR processing fails" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Image).to receive(:open).and_return(double(resize: nil, colorspace: nil, contrast: nil, adaptive_threshold: nil, write: nil))
      allow(Open3).to receive(:capture3).and_return(["", "Error message", double(success?: false)])
      
      expect {
        OmrService.process_image('/path/to/image.png')
      }.to raise_error(OmrService::OmrError, "OMR processing failed: Error message")
    end

    it "raises an error when MusicXML validation fails" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Image).to receive(:open).and_return(double(resize: nil, colorspace: nil, contrast: nil, adaptive_threshold: nil, write: nil))
      allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
      allow(Dir).to receive(:glob).and_return(['/path/to/output.musicxml'])
      allow(File).to receive(:read).and_return("<invalid>xml</invalid>")
      
      expect(OmrService).to receive(:validate_musicxml).and_raise(OmrService::OmrError.new("Invalid MusicXML generated: Invalid XML"))
      
      expect {
        OmrService.process_image('/path/to/image.png')
      }.to raise_error(OmrService::OmrError, "Invalid MusicXML generated: Invalid XML")
    end
  end
end