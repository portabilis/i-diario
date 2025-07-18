class AddIndexApiCodeToRoundingTables < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :rounding_tables, :api_code, algorithm: :concurrently unless index_exists?(:rounding_tables, :api_code)
  end
  
  def down
    remove_index :rounding_tables, :api_code if index_exists?(:rounding_tables, :api_code)
  end
end