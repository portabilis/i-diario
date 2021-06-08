class AddTypeOfTeachingToGeneralConfigurations < ActiveRecord::Migration
  def change
    remove_column :general_configurations, :type_of_teaching
    remove_column :general_configurations, :types_of_teaching
    add_column :general_configurations, :type_of_teaching, :boolean, default: false
    add_column :general_configurations, :types_of_teaching, :integer, array: true, default: [1]
  end
end
