class RemoveXmlDataFromScores < ActiveRecord::Migration[7.1]
  def change
    remove_column :scores, :xml_data, :text
  end
end
