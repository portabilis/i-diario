class AddDisplayKnowledgeAreaAsDisciplineToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :display_knowledge_area_as_discipline, :boolean, default: false
  end
end
