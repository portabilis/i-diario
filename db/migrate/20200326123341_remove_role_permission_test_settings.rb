class RemoveRolePermissionTestSettings < ActiveRecord::Migration
  def change
    RolePermission.where(feature: 'test_settings').destroy_all
  end
end
