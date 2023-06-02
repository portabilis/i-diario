class ResetStudentsWithDeficienciesSync < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
     UPDATE students
        SET uses_differentiated_exam_rule = false,
            updated_at = updated_at - '1 minute'::interval
      WHERE uses_differentiated_exam_rule
    SQL
  end
end
