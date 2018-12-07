class RemoveDuplicatedConceptualExamValues < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE conceptual_exam_value record;
        DECLARE correct_conceptual_exam_value_id INT;
        DECLARE conceptual_exam_value_to_delete record;
      BEGIN
        FOR conceptual_exam_value IN (
          SELECT conceptual_exams.classroom_id,
                 conceptual_exams.student_id,
                 step.step_id,
                 conceptual_exam_values.discipline_id
            FROM conceptual_exams
            JOIN conceptual_exam_values
              ON conceptual_exam_values.conceptual_exam_id = conceptual_exams.id,
                 step_by_classroom(
                   conceptual_exams.classroom_id,
                   conceptual_exams.recorded_at
                 ) AS step
        GROUP BY conceptual_exams.classroom_id,
                 conceptual_exams.student_id,
                 step.step_id,
                 conceptual_exam_values.discipline_id
          HAVING COUNT(1) > 1
        )
        LOOP
          SELECT conceptual_exam_values.id
            INTO correct_conceptual_exam_value_id
            FROM conceptual_exams
            JOIN conceptual_exam_values
              ON conceptual_exam_values.conceptual_exam_id = conceptual_exams.id,
                 step_by_classroom(
                   conceptual_exams.classroom_id,
                   conceptual_exams.recorded_at
                 ) AS step
           WHERE conceptual_exams.classroom_id = conceptual_exam_value.classroom_id
             AND conceptual_exams.student_id = conceptual_exam_value.student_id
             AND conceptual_exam_values.discipline_id = conceptual_exam_value.discipline_id
             AND step.step_id = conceptual_exam_value.step_id
        ORDER BY COALESCE(conceptual_exam_values.value, 0) DESC
           LIMIT 1;

          FOR conceptual_exam_value_to_delete IN (
            SELECT conceptual_exam_values.id
              FROM conceptual_exams
              JOIN conceptual_exam_values
                ON conceptual_exam_values.conceptual_exam_id = conceptual_exams.id,
                   step_by_classroom(
                     conceptual_exams.classroom_id,
                     conceptual_exams.recorded_at
                   ) AS step
             WHERE conceptual_exams.classroom_id = conceptual_exam_value.classroom_id
               AND conceptual_exams.student_id = conceptual_exam_value.student_id
               AND conceptual_exam_values.discipline_id = conceptual_exam_value.discipline_id
               AND step.step_id = conceptual_exam_value.step_id
               AND conceptual_exam_values.id <> correct_conceptual_exam_value_id
          )
          LOOP
            DELETE FROM conceptual_exam_values WHERE id = conceptual_exam_value_to_delete.id;
          END LOOP;
        END LOOP;
      END$$;
    SQL
  end
end
