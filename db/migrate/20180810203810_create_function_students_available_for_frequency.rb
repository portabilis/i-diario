class CreateFunctionStudentsAvailableForFrequency < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION students_available_for_frequency(
        l_classroom_id INT,
        l_discipline_id INT,
        l_frequency_date DATE,
        l_step_number INT
      )
      RETURNS TABLE (
        student_id INT
      ) AS $$
      DECLARE
        exempted_student_enrollments record;
      BEGIN
        SELECT seed.student_enrollment_id AS id
          INTO exempted_student_enrollments
          FROM student_enrollment_exempted_disciplines AS seed
         WHERE seed.discipline_id = l_discipline_id
           AND l_step_number = ANY(string_to_array(steps, ',')::integer[]);

        RETURN QUERY (
          SELECT DISTINCT se.student_id
            FROM student_enrollments AS se
            JOIN student_enrollment_classrooms AS sec
              ON sec.student_enrollment_id = se.id
           WHERE sec.classroom_id = l_classroom_id
             AND l_frequency_date >= CAST(sec.joined_at AS DATE)
             AND (COALESCE(sec.left_at, '') = '' OR l_frequency_date < CAST(sec.left_at AS DATE))
             AND se.active = 1
             AND (exempted_student_enrollments.id IS NULL OR se.id NOT IN (exempted_student_enrollments.id))
             AND (l_discipline_id IS NULL OR
                  NOT EXISTS(SELECT 1
                               FROM student_enrollment_dependences
                              WHERE student_enrollment_dependences.student_enrollment_id = se.id) OR
                  EXISTS(SELECT 1
                           FROM student_enrollment_dependences
                          WHERE student_enrollment_dependences.student_enrollment_id = se.id
                            AND student_enrollment_dependences.discipline_id = l_discipline_id)
                )
        );

        RETURN;
      END; $$
      LANGUAGE 'plpgsql';
    SQL
  end
end
