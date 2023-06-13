class UpdateUsersCurrentUserRoleIdWithWrongUnityId < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users
        SET current_user_role_id = NULL
      WHERE EXISTS(
              SELECT 1
                FROM user_roles
               WHERE user_roles.id = users.current_user_role_id
                 AND user_roles.unity_id <> users.current_unity_id
            )
    SQL
  end
end
