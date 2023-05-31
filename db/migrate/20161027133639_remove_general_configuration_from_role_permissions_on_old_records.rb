class RemoveGeneralConfigurationFromRolePermissionsOnOldRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM role_permissions WHERE feature = 'general_configurations';
    SQL
  end
end
