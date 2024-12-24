class CreateKnowledgeAreaContentRecordsAreas < ActiveRecord::Migration[4.2]
  def change
    create_table :knowledge_area_content_records_areas do |t|
      t.integer :knowledge_area_content_record_id, null: false
      t.integer :knowledge_area_id, null: false
    end
    add_index :knowledge_area_content_records_areas, :knowledge_area_content_record_id, name: "content_record_on_knowledge_area_content_records_areas_idx"
    add_index :knowledge_area_content_records_areas, :knowledge_area_id, name: "knowledge_area_on_knowledge_area_content_records_areas_idx"
    add_foreign_key :knowledge_area_content_records_areas, :knowledge_area_content_records, name: "content_record_on_knowledge_area_content_records_areas_idx"
    add_foreign_key :knowledge_area_content_records_areas, :knowledge_areas, name: "knowledge_area_on_knowledge_area_content_records_areas_idx"
  end
end
