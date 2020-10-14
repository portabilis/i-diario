class AddCurrentKnowledgeAreaIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_knowledge_area_id, :integer
    add_foreign_key :users, :knowledge_areas, column: :current_knowledge_area_id
  end
end
