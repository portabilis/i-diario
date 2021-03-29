class RemoveRolePermissionTestSettings < ActiveRecord::Migration
  def change
    RolePermission.where(feature: 'test_settings').each do |role_permission|
      role_permission.without_auditing do
        role_permission.destroy
      end
    end
  end
end
