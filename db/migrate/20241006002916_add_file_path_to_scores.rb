class AddFilePathToScores < ActiveRecord::Migration[7.1]
  def change

    add_column :scores, :file_path, :string
  end
end
