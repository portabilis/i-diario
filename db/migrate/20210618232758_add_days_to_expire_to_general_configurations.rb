class AddDaysToExpireToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :days_to_expire_password, :integer, default: 0
    add_column :general_configurations, :days_to_disable_access, :integer, default: 0
  end
end
