class AddErrorMessageToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :error_message, :string
  end
end
