class UpdateCurrentClassroomIdToTeachersWithWrongValue < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE users
      SET current_classroom_id = u.classroom_id, current_unity_id = u.unity_id
      FROM
        (SELECT
          usuario.id,
          (SELECT teacher_discipline_classrooms.classroom_id
            FROM teacher_discipline_classrooms
            WHERE teacher_discipline_classrooms.teacher_id = teachers.id
            AND active = true
            ORDER BY created_at DESC limit 1) AS classroom_id,
          (SELECT classrooms.unity_id
            FROM classrooms
            JOIN teacher_discipline_classrooms on teacher_discipline_classrooms.classroom_id = classrooms.id
            WHERE teacher_discipline_classrooms.teacher_id = teachers.id and active = true
            ORDER BY teachers.created_at DESC limit 1) AS unity_id
        FROM users as usuario
          JOIN teachers on teachers.id = usuario.teacher_id
          JOIN user_roles on user_roles.user_id = usuario.id AND user_roles.id = usuario.current_user_role_id
          JOIN roles on user_roles.role_id = roles.id AND roles.access_level = 'teacher'
        WHERE usuario.current_classroom_id IS NOT NULL
        AND NOT EXISTS
          (SELECT *
            FROM teacher_discipline_classrooms
            WHERE teacher_discipline_classrooms.teacher_id = teachers.id
            AND usuario.current_classroom_id = classroom_id)
        ) u
      WHERE u.id = users.id;
    SQL
  end
end
