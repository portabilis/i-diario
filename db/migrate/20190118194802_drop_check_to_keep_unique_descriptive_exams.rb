class DropCheckToKeepUniqueDescriptiveExams < ActiveRecord::Migration
  def change
    execute <<-SQL
      ALTER TABLE descriptive_exams
      DROP CONSTRAINT check_descriptive_exam_is_unique;
    SQL
  end
end
