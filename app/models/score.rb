class Score < ApplicationRecord
  validates :file_path, presence: true, uniqueness: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_creation_date, ->(date) { where(created_at: date.beginning_of_day..date.end_of_day) }
  
  def file_exists?
    File.exist?(file_path)
  end
end