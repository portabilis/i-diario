class InsertStepNumberInConceptualExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE conceptual_exams
         SET step_number = (
           SELECT COALESCE(MAX(step.step_number), 0)
             FROM step_by_classroom(
                    conceptual_exams.classroom_id,
                    conceptual_exams.recorded_at
                  ) AS step
         );
    SQL
  end
end
