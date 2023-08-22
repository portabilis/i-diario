class AddGroupChildrenEducationToGeneralConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :general_configurations, :group_children_education, :boolean, default: false
  end
end
