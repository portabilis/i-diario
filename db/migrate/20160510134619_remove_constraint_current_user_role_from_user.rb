class RemoveConstraintCurrentUserRoleFromUser < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP INDEX index_users_on_current_user_role_id;
      ALTER TABLE users DROP CONSTRAINT IF EXISTS users_current_user_role_id_fk;
    SQL
  end
end
