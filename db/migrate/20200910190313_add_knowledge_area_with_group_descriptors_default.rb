class AddKnowledgeAreaWithGroupDescriptorsDefault < ActiveRecord::Migration
  def change
    change_column :knowledge_areas, :group_descriptors, :boolean, default: false
  end
end
