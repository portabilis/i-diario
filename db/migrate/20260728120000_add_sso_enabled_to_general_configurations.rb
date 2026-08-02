class AddSsoEnabledToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :sso_enabled, :boolean, default: false
  end
end
