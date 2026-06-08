class AddAllowAutomaticRecoveryToGeneralConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :general_configurations, :allow_automatic_avaliation_recovery, :boolean, default: false
  end
end
