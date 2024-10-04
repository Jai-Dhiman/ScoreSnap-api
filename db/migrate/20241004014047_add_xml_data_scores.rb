class AddXmlDataScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :xml_data, :text, null: false
  end
end
