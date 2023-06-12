class AddIndexKnowledgeAreasOnGroupDescriptors < ActiveRecord::Migration[4.2]
  def change
    add_index :knowledge_areas, :group_descriptors
  end
end
