class AddBackupFileToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :backup_file, :string
    add_column :general_configurations, :backup_status, :string
  end
end
