class RemoveColumnSupportFreshdeskFromGeneralConfigurations < ActiveRecord::Migration[4.2]
  def up
    remove_column :general_configurations, :support_freshdesk
  end

  def down
    add_column :general_configurations, :support_freshdesk, :string
  end
end
