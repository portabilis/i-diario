class RenameTestsToAvaliations < ActiveRecord::Migration[4.2]
  def change
    rename_table :tests, :avaliations
  end
end
