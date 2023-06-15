class InsertPermissionsToCustomRoundingTables < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      INSERT INTO role_permissions(role_id, feature, permission, created_at, updated_at)
      SELECT id, 'custom_rounding_tables', 'change', CURRENT_DATE, CURRENT_DATE FROM roles WHERE access_level IN ('administrator', 'employee');
    SQL
  end
end
