class DropCheckToKeepUniqueConceptualExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      ALTER TABLE conceptual_exams
      DROP CONSTRAINT check_conceptual_exam_is_unique;
    SQL
  end
end
