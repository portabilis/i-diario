class AddIndexApiCodeToKnowledgeAreas < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :knowledge_areas, :api_code, algorithm: :concurrently unless index_exists?(:knowledge_areas, :api_code)
  end
  
  def down
    remove_index :knowledge_areas, :api_code if index_exists?(:knowledge_areas, :api_code)
  end
end