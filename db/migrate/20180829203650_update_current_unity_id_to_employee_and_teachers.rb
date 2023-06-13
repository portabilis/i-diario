class UpdateCurrentUnityIdToEmployeeAndTeachers < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users
         SET current_unity_id = (
           SELECT unity_id
             FROM classrooms
            WHERE id = current_classroom_id
         )
       WHERE current_unity_id IS NULL AND
             current_classroom_id IS NOT NULL
    SQL
  end
end
