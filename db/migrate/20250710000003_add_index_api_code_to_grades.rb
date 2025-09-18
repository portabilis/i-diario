class AddIndexApiCodeToGrades < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :grades, :api_code, algorithm: :concurrently unless index_exists?(:grades, :api_code)
  end
  
  def down
    remove_index :grades, :api_code if index_exists?(:grades, :api_code)
  end
end