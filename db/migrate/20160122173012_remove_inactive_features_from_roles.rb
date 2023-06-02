class RemoveInactiveFeaturesFromRoles < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM role_permissions WHERE feature = 'lesson_plan_report';
      DELETE FROM role_permissions WHERE feature = 'tests';
    SQL
  end
end
