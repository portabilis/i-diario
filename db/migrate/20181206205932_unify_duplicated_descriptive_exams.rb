class UnifyDuplicatedDescriptiveExams < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE descriptive_exam record;
        DECLARE descriptive_exam_student_to_move record;
        DECLARE correct_descriptive_exam_id INT;
      BEGIN
        FOR descriptive_exam IN (
          SELECT descriptive_exams.classroom_id,
                 descriptive_exams.discipline_id,
                 step.step_id
            FROM descriptive_exams,
                 step_by_classroom(
                   descriptive_exams.classroom_id,
                   descriptive_exams.recorded_at
                 ) AS step
        GROUP BY descriptive_exams.classroom_id,
                 descriptive_exams.discipline_id,
                 step.step_id
          HAVING COUNT(1) > 1
        )
        LOOP
          SELECT descriptive_exams.id
            INTO correct_descriptive_exam_id
            FROM descriptive_exams,
                 step_by_classroom(
                   descriptive_exams.classroom_id,
                   descriptive_exams.recorded_at
                 ) AS step
           WHERE descriptive_exams.classroom_id = descriptive_exam.classroom_id
             AND COALESCE(descriptive_exams.discipline_id, 0) = COALESCE(descriptive_exam.discipline_id, 0)
             AND step.step_id = descriptive_exam.step_id
        ORDER BY descriptive_exams.created_at
           LIMIT 1;

          FOR descriptive_exam_student_to_move IN (
            SELECT descriptive_exam_students.id
              FROM descriptive_exams
              JOIN descriptive_exam_students
                ON descriptive_exam_students.descriptive_exam_id = descriptive_exams.id,
                   step_by_classroom(
                     descriptive_exams.classroom_id,
                     descriptive_exams.recorded_at
                   ) AS step
             WHERE descriptive_exams.classroom_id = descriptive_exam.classroom_id
               AND COALESCE(descriptive_exams.discipline_id, 0) = COALESCE(descriptive_exam.discipline_id, 0)
               AND step.step_id = descriptive_exam.step_id
               AND descriptive_exam_students.id <> correct_descriptive_exam_id
          )
          LOOP
            UPDATE descriptive_exam_students
               SET descriptive_exam_id = correct_descriptive_exam_id
             WHERE id = descriptive_exam_student_to_move.id;
          END LOOP;
        END LOOP;

        DELETE
          FROM descriptive_exams
         WHERE NOT EXISTS(
                 SELECT 1
                   FROM descriptive_exam_students
                  WHERE descriptive_exam_students.descriptive_exam_id = descriptive_exams.id
               );
      END$$;
    SQL
  end
end
