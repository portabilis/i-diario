class AddIndexGroupDescriptorsToKnowledgeAreas < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :knowledge_areas, :group_descriptors, algorithm: :concurrently unless index_exists?(:knowledge_areas, :group_descriptors)
  end
  
  def down
    remove_index :knowledge_areas, :group_descriptors if index_exists?(:knowledge_areas, :group_descriptors)
  end
end