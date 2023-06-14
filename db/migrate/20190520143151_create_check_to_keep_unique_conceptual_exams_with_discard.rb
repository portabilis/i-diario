class CreateCheckToKeepUniqueConceptualExamsWithDiscard < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      ALTER TABLE conceptual_exams
      ADD CONSTRAINT check_conceptual_exam_is_unique
      CHECK (
        check_conceptual_exam_is_unique(id, classroom_id, student_id, step_number, discarded_at)
      ) NOT VALID;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE conceptual_exams
      DROP CONSTRAINT check_conceptual_exam_is_unique;
    SQL
  end
end
