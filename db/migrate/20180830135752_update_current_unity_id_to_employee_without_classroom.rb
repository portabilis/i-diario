class UpdateCurrentUnityIdToEmployeeWithoutClassroom < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users
         SET current_unity_id = (
           SELECT user_roles.unity_id
             FROM user_roles
            WHERE user_roles.id = users.current_user_role_id
         )
       WHERE kind = 'employee' AND
             current_user_role_id IS NOT NULL AND
             current_unity_id IS NULL
    SQL
  end
end
