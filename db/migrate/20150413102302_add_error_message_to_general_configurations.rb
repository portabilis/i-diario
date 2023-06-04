class AddErrorMessageToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :error_message, :string
  end
end
