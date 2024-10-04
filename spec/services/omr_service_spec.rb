require 'rails_helper'

RSpec.describe OmrService do
  describe ".process_image" do
    it "processes an image and returns XML data" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:glob).and_return(['/path/to/output.musicxml'])
      allow(File).to receive(:read).and_return("<score></score>")
      allow_any_instance_of(Object).to receive(:system).and_return(true)

      result = OmrService.process_image('/path/to/image.png')
      expect(result).to eq("<score></score>")
    end

    it "raises an error when processing fails" do
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:glob).and_return([])
      allow_any_instance_of(Object).to receive(:system).and_return(false)

      expect {
        OmrService.process_image('/path/to/image.png')
      }.to raise_error(RuntimeError, "OMR processing failed: No output file generated")
    end
  end
end