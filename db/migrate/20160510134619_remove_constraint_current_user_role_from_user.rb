class RemoveConstraintCurrentUserRoleFromUser < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP INDEX index_users_on_current_user_role_id;
      ALTER TABLE users DROP CONSTRAINT users_current_user_role_id_fk;
    SQL
  end
end
