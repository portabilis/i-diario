class UpdateKnowledgeAreaWithGrupDescriptorsFalse < ActiveRecord::Migration
  def change
    execute <<-SQL
      update knowledge_areas
         set group_descriptors = false
    SQL
  end
end
