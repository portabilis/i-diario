class CreateFunctionCheckToKeepUniqueConceptualExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_conceptual_exam_is_unique(
        _id INT,
        _classroom_id INT,
        _student_id INT,
        _recorded_at DATE
      )
        RETURNS BOOLEAN AS
      $$
      DECLARE
        _current_step_id INT;
      BEGIN
        SELECT step_id
          INTO _current_step_id
          FROM step_by_classroom(
                 _classroom_id,
                 _recorded_at
               ) AS step;

        IF NOT EXISTS(
          SELECT 1
            FROM conceptual_exams,
                 step_by_classroom(
                   conceptual_exams.classroom_id,
                   conceptual_exams.recorded_at
                 ) AS step
           WHERE conceptual_exams.classroom_id = _classroom_id
             AND conceptual_exams.student_id = _student_id
             AND step.step_id = _current_step_id
             AND conceptual_exams.id <> _id
        ) THEN
          RETURN TRUE;
        END IF;

        RETURN FALSE;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end
end
