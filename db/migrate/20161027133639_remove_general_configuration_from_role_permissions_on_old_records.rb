class RemoveGeneralConfigurationFromRolePermissionsOnOldRecords < ActiveRecord::Migration
  def change
    execute <<-SQL
      DELETE FROM role_permissions WHERE feature = 'general_configurations';
    SQL
  end
end
