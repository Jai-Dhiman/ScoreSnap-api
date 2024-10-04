require 'rails_helper'

RSpec.describe Score, type: :model do
  it "is valid with valid attributes" do
    score = Score.new(xml_data: "<score><measure></measure></score>")
    expect(score).to be_valid
  end

  it "is not valid without xml_data" do
    score = Score.new(xml_data: nil)
    expect(score).to_not be_valid
  end

  it "is not valid with invalid XML" do
    score = Score.new(xml_data: "invalid xml")
    expect(score).to_not be_valid
  end
end