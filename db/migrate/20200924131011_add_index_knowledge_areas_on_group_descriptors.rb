class AddIndexKnowledgeAreasOnGroupDescriptors < ActiveRecord::Migration
  def change
    add_index :knowledge_areas, :group_descriptors
  end
end
