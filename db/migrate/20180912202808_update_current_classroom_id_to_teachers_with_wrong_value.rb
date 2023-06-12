class UpdateCurrentClassroomIdToTeachersWithWrongValue < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
    UPDATE users
    SET
      current_classroom_id = user_row.classroom_id,
      current_unity_id = user_row.unity_id,
      current_discipline_id = user_row.current_discipline_id
    FROM(
      SELECT
        users.id AS user_id,
        lateral_correct_values.unity_id AS unity_id,
        lateral_correct_values.classroom_id AS classroom_id,
        lateral_correct_values.current_discipline_id AS current_discipline_id
      FROM users
      JOIN user_roles ON user_roles.user_id = users.id AND user_roles.id = users.current_user_role_id
      JOIN roles ON user_roles.role_id = roles.id AND roles.access_level = 'teacher'
      JOIN teachers ON teachers.id = users.teacher_id,
      LATERAL(
        SELECT
          teacher_discipline_classrooms.classroom_id AS classroom_id,
          teacher_discipline_classrooms.discipline_id AS current_discipline_id,
          classrooms.unity_id AS unity_id
        FROM teacher_discipline_classrooms
        JOIN classrooms ON teacher_discipline_classrooms.classroom_id = classrooms.id
        WHERE teacher_discipline_classrooms.teacher_id = teachers.id AND teachers.active = true
        ORDER BY teachers.created_at DESC
        LIMIT 1
      ) AS lateral_correct_values
      WHERE NOT EXISTS
        (SELECT 1
          FROM teacher_discipline_classrooms
          WHERE teacher_discipline_classrooms.teacher_id = teachers.id
          AND users.current_classroom_id = teacher_discipline_classrooms.classroom_id)
      ) AS user_row
    WHERE user_row.user_id = users.id;
    SQL
  end
end
