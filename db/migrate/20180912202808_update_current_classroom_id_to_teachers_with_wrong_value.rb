class UpdateCurrentClassroomIdToTeachersWithWrongValue < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE users
        SET current_classroom_id = u.classroom_id
          FROM
            (SELECT
              usuario.id,
              (SELECT teacher_discipline_classrooms.classroom_id certo
                FROM teacher_discipline_classrooms
                WHERE teacher_discipline_classrooms.teacher_id = teachers.id
                  AND active = true
                ORDER BY created_at DESC limit 1) classroom_id
            FROM users usuario
              INNER JOIN teachers on teachers.id = usuario.teacher_id
              INNER JOIN user_roles on user_roles.user_id = usuario.id AND user_roles.id = usuario.current_user_role_id
              INNER JOIN roles on user_roles.role_id = roles.id AND roles.access_level = 'teacher'
            WHERE usuario.current_classroom_id IS NOT NULL
              AND usuario.current_classroom_id NOT IN
                (SELECT classroom_id FROM teacher_discipline_classrooms WHERE teacher_discipline_classrooms.teacher_id = teachers.id)
            ) u
      WHERE u.id = users.id;
    SQL
  end
end
