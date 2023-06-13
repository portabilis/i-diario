class RemoveInvalidUserRolesFromUsersAndAddFk < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users
      SET current_user_role_id = null
      WHERE current_user_role_id is not null
      AND NOT EXISTS (select 1 from user_roles where id = current_user_role_id)
    SQL

    add_foreign_key :users, :user_roles, column: :current_user_role_id
  end
end
