class UnifyDuplicatedConceptualExams < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE conceptual_exam record;
        DECLARE correct_conceptual_exam_id INT;
        DECLARE conceptual_exam_value_to_move record;
      BEGIN
        FOR conceptual_exam IN (
          SELECT conceptual_exams.classroom_id,
                 conceptual_exams.student_id,
                 step.step_id
            FROM conceptual_exams,
                 step_by_classroom(
                   conceptual_exams.classroom_id,
                   conceptual_exams.recorded_at
                 ) AS step
        GROUP BY conceptual_exams.classroom_id,
                 conceptual_exams.student_id,
                 step.step_id
          HAVING COUNT(1) > 1
        )
        LOOP
          SELECT conceptual_exams.id
            INTO correct_conceptual_exam_id
            FROM conceptual_exams,
                 step_by_classroom(
                   conceptual_exams.classroom_id,
                   conceptual_exams.recorded_at
                 ) AS step
           WHERE conceptual_exams.classroom_id = conceptual_exam.classroom_id
             AND conceptual_exams.student_id = conceptual_exam.student_id
             AND step.step_id = conceptual_exam.step_id
        ORDER BY conceptual_exams.created_at
           LIMIT 1;

          FOR conceptual_exam_value_to_move IN (
            SELECT conceptual_exam_values.id
              FROM conceptual_exams
              JOIN conceptual_exam_values
                ON conceptual_exam_values.conceptual_exam_id = conceptual_exams.id,
                   step_by_classroom(
                     conceptual_exams.classroom_id,
                     conceptual_exams.recorded_at
                   ) AS step
             WHERE conceptual_exams.classroom_id = conceptual_exam.classroom_id
               AND conceptual_exams.student_id = conceptual_exam.student_id
               AND step.step_id = conceptual_exam.step_id
               AND conceptual_exam_values.id <> correct_conceptual_exam_id
          )
          LOOP
            UPDATE conceptual_exam_values
               SET conceptual_exam_id = correct_conceptual_exam_id
             WHERE id = conceptual_exam_value_to_move.id;
          END LOOP;
        END LOOP;

        DELETE
          FROM conceptual_exams
         WHERE NOT EXISTS(
                 SELECT 1
                   FROM conceptual_exam_values
                  WHERE conceptual_exam_values.conceptual_exam_id = conceptual_exams.id
               );
      END$$;
    SQL
  end
end
