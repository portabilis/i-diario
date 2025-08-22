class AddIndexApiCodeToExamRules < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :exam_rules, :api_code, algorithm: :concurrently unless index_exists?(:exam_rules, :api_code)
  end
  
  def down
    remove_index :exam_rules, :api_code if index_exists?(:exam_rules, :api_code)
  end
end