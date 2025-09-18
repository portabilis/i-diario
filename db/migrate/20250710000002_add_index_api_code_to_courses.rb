class AddIndexApiCodeToCourses < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :courses, :api_code, algorithm: :concurrently unless index_exists?(:courses, :api_code)
  end
  
  def down
    remove_index :courses, :api_code if index_exists?(:courses, :api_code)
  end
end