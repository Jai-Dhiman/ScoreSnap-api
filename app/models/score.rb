class Score < ApplicationRecord
  validates :xml_data, presence: true
  validate :valid_xml_format

  private

  def valid_xml_format
    Nokogiri::XML(xml_data) { |config| config.strict }
  rescue Nokogiri::XML::SyntaxError => e
    errors.add(:xml_data, "is not valid XML: #{e.message}")
  end
end