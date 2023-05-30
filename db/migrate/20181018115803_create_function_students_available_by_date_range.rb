class CreateFunctionStudentsAvailableByDateRange < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION students_available_by_date_range(
        l_classroom_id INT,
        l_discipline_id INT,
        l_start_at DATE,
        l_end_at DATE,
        l_step_number INT
      )
      RETURNS TABLE (
        student_id INT
      ) AS $$
      DECLARE
        exempted_student_enrollment_id INT;
      BEGIN
        SELECT student_enrollment_exempted_disciplines.student_enrollment_id
          INTO exempted_student_enrollment_id
          FROM student_enrollment_exempted_disciplines
         WHERE student_enrollment_exempted_disciplines.discipline_id = l_discipline_id
           AND l_step_number = ANY(string_to_array(student_enrollment_exempted_disciplines.steps, ',')::integer[]);

        RETURN QUERY (
          SELECT DISTINCT student_enrollments.student_id
            FROM student_enrollments
            JOIN student_enrollment_classrooms
              ON student_enrollment_classrooms.student_enrollment_id = student_enrollments.id
           WHERE student_enrollment_classrooms.classroom_id = l_classroom_id
             AND student_enrollments.active = 1
             AND CASE
                   WHEN COALESCE(student_enrollment_classrooms.left_at) = '' THEN
                     CAST(student_enrollment_classrooms.joined_at AS DATE) <= l_end_at
                   ELSE
                     CAST(student_enrollment_classrooms.joined_at AS DATE) <= l_end_at AND
                     CAST(student_enrollment_classrooms.left_at AS DATE) >= l_start_at AND
                     CAST(student_enrollment_classrooms.joined_at AS DATE) <> CAST(student_enrollment_classrooms.left_at AS DATE)
                 END
             AND (
                   exempted_student_enrollment_id IS NULL OR
                   student_enrollments.id NOT IN (exempted_student_enrollment_id)
                 )
             AND (
                  l_discipline_id IS NULL OR
                  NOT EXISTS(
                    SELECT 1
                      FROM student_enrollment_dependences
                     WHERE student_enrollment_dependences.student_enrollment_id = student_enrollments.id
                  ) OR
                  EXISTS(
                    SELECT 1
                      FROM student_enrollment_dependences
                     WHERE student_enrollment_dependences.student_enrollment_id = student_enrollments.id
                       AND student_enrollment_dependences.discipline_id = l_discipline_id
                  )
                )
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
