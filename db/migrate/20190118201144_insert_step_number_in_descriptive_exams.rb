class InsertStepNumberInDescriptiveExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE descriptive_exams
         SET step_number = (
           SELECT COALESCE(MAX(step.step_number), 0)
             FROM step_by_classroom(
                    descriptive_exams.classroom_id,
                    descriptive_exams.recorded_at
                  ) AS step
         );
    SQL
  end
end
