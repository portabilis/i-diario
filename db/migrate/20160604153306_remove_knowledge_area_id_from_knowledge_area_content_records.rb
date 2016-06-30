class RemoveKnowledgeAreaIdFromKnowledgeAreaContentRecords < ActiveRecord::Migration
  def change
    remove_column :knowledge_area_content_records, :knowledge_area_id
  end
end
