class RemoveColumnFromGeneralConfigurations < ActiveRecord::Migration
  def change
    remove_column :general_configurations, :display_knowledge_area_as_discipline
  end
end
