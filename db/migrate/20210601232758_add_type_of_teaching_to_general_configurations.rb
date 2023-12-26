class AddTypeOfTeachingToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :type_of_teaching, :boolean, default: false
    add_column :general_configurations, :types_of_teaching, :integer, array: true, default: [1]
  end
end
