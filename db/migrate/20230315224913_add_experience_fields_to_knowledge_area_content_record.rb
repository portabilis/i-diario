class AddExperienceFieldsToKnowledgeAreaContentRecord < ActiveRecord::Migration
  def change
    add_column :knowledge_area_content_records, :experience_fields, :string
  end
end
