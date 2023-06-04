class AddColumnAllowsAfterSalesRelationshipToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :allows_after_sales_relationship, :string, default: "allows"
  end
end
