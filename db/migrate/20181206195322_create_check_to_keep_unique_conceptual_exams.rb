class CreateCheckToKeepUniqueConceptualExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      ALTER TABLE conceptual_exams
      ADD CONSTRAINT check_conceptual_exam_is_unique
      CHECK (check_conceptual_exam_is_unique(id, classroom_id, student_id, recorded_at)) NOT VALID;
    SQL
  end
end
