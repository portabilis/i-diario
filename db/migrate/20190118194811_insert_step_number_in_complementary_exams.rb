class InsertStepNumberInComplementaryExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE complementary_exams
         SET step_number = (
           SELECT COALESCE(MAX(step.step_number), 0)
             FROM step_by_classroom(
                    complementary_exams.classroom_id,
                    complementary_exams.recorded_at
                  ) AS step
         );
    SQL
  end
end
