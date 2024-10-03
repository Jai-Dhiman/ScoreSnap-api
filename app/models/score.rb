class Score < ApplicationRecord
  validates :xml_data, presence: true
end
