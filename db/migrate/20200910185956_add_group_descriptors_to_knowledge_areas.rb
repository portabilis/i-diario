class AddGroupDescriptorsToKnowledgeAreas < ActiveRecord::Migration
  def change
    add_column :knowledge_areas, :group_descriptors, :boolean, default: false
  end
end
