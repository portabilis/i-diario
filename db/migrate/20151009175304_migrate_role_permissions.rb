class MigrateRolePermissions < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      INSERT INTO role_permissions(role_id, feature, permission, created_at, updated_at) SELECT role_id, 'knowledge_area_lesson_plans', permission, localtimestamp, localtimestamp FROM role_permissions WHERE feature = 'contents';
      INSERT INTO role_permissions(role_id, feature, permission, created_at, updated_at) SELECT role_id, 'discipline_lesson_plans', permission, localtimestamp, localtimestamp FROM role_permissions WHERE feature = 'contents';
      DELETE FROM role_permissions WHERE feature = 'contents';
    SQL
  end
end
