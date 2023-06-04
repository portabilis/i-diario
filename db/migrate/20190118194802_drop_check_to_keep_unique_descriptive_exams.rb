class DropCheckToKeepUniqueDescriptiveExams < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      ALTER TABLE descriptive_exams
      DROP CONSTRAINT check_descriptive_exam_is_unique;
    SQL
  end
end
