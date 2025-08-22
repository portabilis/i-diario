class AddIndexApiCodeToUnities < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :unities, :api_code, algorithm: :concurrently unless index_exists?(:unities, :api_code)
  end
  
  def down
    remove_index :unities, :api_code if index_exists?(:unities, :api_code)
  end
end