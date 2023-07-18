class RemoveColumnFromGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    remove_column :general_configurations, :display_knowledge_area_as_discipline
  end
end
