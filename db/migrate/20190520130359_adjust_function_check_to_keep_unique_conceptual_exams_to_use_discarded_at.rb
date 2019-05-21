class AdjustFunctionCheckToKeepUniqueConceptualExamsToUseDiscardedAt < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP FUNCTION check_conceptual_exam_is_unique(INT, INT, INT, INT);

      CREATE OR REPLACE FUNCTION check_conceptual_exam_is_unique(
        _id INT,
        _classroom_id INT,
        _student_id INT,
        _step_number INT,
        _discarded_at TIMESTAMP
      )
        RETURNS BOOLEAN AS
      $$
      BEGIN
        IF _discarded_at IS NOT NULL THEN
          RETURN TRUE;
        END IF;

        IF NOT EXISTS(
          SELECT 1
            FROM conceptual_exams
           WHERE conceptual_exams.classroom_id = _classroom_id
             AND conceptual_exams.student_id = _student_id
             AND conceptual_exams.step_number = _step_number
             AND conceptual_exams.id <> _id
             AND conceptual_exams.discarded_at IS NULL
        ) THEN
          RETURN TRUE;
        END IF;

        RETURN FALSE;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end
end
