class AddDisplayKnowledgeAreaAsDisciplineToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :display_knowledge_area_as_discipline, :boolean, default: false
  end
end
