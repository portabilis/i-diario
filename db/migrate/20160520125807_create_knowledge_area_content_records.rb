class CreateKnowledgeAreaContentRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :knowledge_area_content_records do |t|
      t.integer :knowledge_area_id, null: false, index: true
      t.integer :content_record_id, null: false, index: { unique: true }

      t.timestamps
    end
    add_foreign_key :knowledge_area_content_records, :content_records
    add_foreign_key :knowledge_area_content_records, :knowledge_areas
  end
end
