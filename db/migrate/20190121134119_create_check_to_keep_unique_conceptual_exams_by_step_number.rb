class CreateCheckToKeepUniqueConceptualExamsByStepNumber < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      ALTER TABLE conceptual_exams
      ADD CONSTRAINT check_conceptual_exam_is_unique
      CHECK (check_conceptual_exam_is_unique(id, classroom_id, student_id, step_number)) NOT VALID;
    SQL
  end
end
