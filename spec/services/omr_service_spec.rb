require 'rails_helper'

RSpec.describe OmrService do
  describe '.process_image' do
    let(:image_path) { 'path/to/test/image.png' }
    let(:output_dir) { Rails.root.join('tmp', 'omr_output') }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:rm_rf)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:readable?).and_return(true)
      allow(MiniMagick::Image).to receive(:open).and_return(double(resize: true, colorspace: true, contrast: true, write: true))
      allow(Open3).to receive(:capture3).and_return(['', '', double(success?: true)])
      allow(Dir).to receive(:glob).and_return(['/path/to/output.musicxml'])
      allow(File).to receive(:read).and_return('<score></score>')
    end

    it 'processes an image and returns XML content' do
      expect(described_class).to receive(:preprocess_image).with(image_path).and_call_original
      expect(described_class).to receive(:run_omr).with(anything, output_dir).and_call_original
      expect(described_class).to receive(:validate_musicxml).with('<score></score>')

      result = described_class.process_image(image_path)
      expect(result).to eq('<score></score>')
    end

    it 'raises an error if OMR processing fails' do
      allow(Open3).to receive(:capture3).and_return(['', 'Error', double(success?: false)])

      expect {
        described_class.process_image(image_path)
      }.to raise_error(OmrService::OmrError, /OMR processing failed/)
    end

    it 'raises an error if no output file is generated' do
      allow(Dir).to receive(:glob).and_return([])

      expect {
        described_class.process_image(image_path)
      }.to raise_error(OmrService::OmrError, /No output file generated/)
    end
  end
end