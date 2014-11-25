class AddBackupFileToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :backup_file, :string
    add_column :general_configurations, :backup_status, :string
  end
end
