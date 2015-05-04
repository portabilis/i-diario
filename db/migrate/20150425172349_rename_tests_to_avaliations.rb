class RenameTestsToAvaliations < ActiveRecord::Migration
  def change
    rename_table :tests, :avaliations
  end
end
