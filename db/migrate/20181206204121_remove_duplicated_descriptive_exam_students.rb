class RemoveDuplicatedDescriptiveExamStudents < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE descriptive_exam_student record;
        DECLARE correct_descriptive_exam_student_id INT;
        DECLARE descriptive_exam_student_to_delete record;
      BEGIN
        FOR descriptive_exam_student IN (
          SELECT descriptive_exams.classroom_id,
                 descriptive_exams.discipline_id,
                 step.step_id,
                 descriptive_exam_students.student_id
            FROM descriptive_exams
            JOIN descriptive_exam_students
              ON descriptive_exam_students.descriptive_exam_id = descriptive_exams.id,
                 step_by_classroom(
                   descriptive_exams.classroom_id,
                   descriptive_exams.recorded_at
                 ) AS step
        GROUP BY descriptive_exams.classroom_id,
                 descriptive_exams.discipline_id,
                 step.step_id,
                 descriptive_exam_students.student_id
          HAVING COUNT(1) > 1
        )
        LOOP
          SELECT descriptive_exam_students.id
            INTO correct_descriptive_exam_student_id
            FROM descriptive_exams
            JOIN descriptive_exam_students
              ON descriptive_exam_students.descriptive_exam_id = descriptive_exams.id,
                 step_by_classroom(
                   descriptive_exams.classroom_id,
                   descriptive_exams.recorded_at
                 ) AS step
           WHERE descriptive_exams.classroom_id = descriptive_exam_student.classroom_id
             AND COALESCE(descriptive_exams.discipline_id, 0) = COALESCE(descriptive_exam_student.discipline_id, 0)
             AND descriptive_exam_students.student_id = descriptive_exam_student.student_id
             AND step.step_id = descriptive_exam_student.step_id
        ORDER BY TRIM(descriptive_exam_students.value) = '', descriptive_exam_students.updated_at DESC
           LIMIT 1;

          FOR descriptive_exam_student_to_delete IN (
            SELECT descriptive_exam_students.id
              FROM descriptive_exams
              JOIN descriptive_exam_students
                ON descriptive_exam_students.descriptive_exam_id = descriptive_exams.id,
                   step_by_classroom(
                     descriptive_exams.classroom_id,
                     descriptive_exams.recorded_at
                   ) AS step
             WHERE descriptive_exams.classroom_id = descriptive_exam_student.classroom_id
               AND COALESCE(descriptive_exams.discipline_id, 0) = COALESCE(descriptive_exam_student.discipline_id, 0)
               AND descriptive_exam_students.student_id = descriptive_exam_student.student_id
               AND step.step_id = descriptive_exam_student.step_id
               AND descriptive_exam_students.id <> correct_descriptive_exam_student_id
          )
          LOOP
            DELETE FROM descriptive_exam_students WHERE id = descriptive_exam_student_to_delete.id;
          END LOOP;
        END LOOP;
      END$$;
    SQL
  end
end
