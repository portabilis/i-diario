class CreateCheckToKeepUniqueDescriptiveExamsByStepNumber < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      ALTER TABLE descriptive_exams
      ADD CONSTRAINT check_descriptive_exam_is_unique
      CHECK (check_descriptive_exam_is_unique(id, classroom_id, discipline_id, step_number)) NOT VALID;
    SQL
  end
end
