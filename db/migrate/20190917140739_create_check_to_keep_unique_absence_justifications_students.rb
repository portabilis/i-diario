class CreateCheckToKeepUniqueAbsenceJustificationsStudents < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      ALTER TABLE absence_justifications_students
      ADD CONSTRAINT check_absence_justification_student_is_unique
      CHECK (
        check_absence_justification_student_is_unique(student_id, absence_justification_id, id, discarded_at)
      ) NOT VALID;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE absence_justifications_students
      DROP CONSTRAINT check_absence_justification_student_is_unique;
    SQL
  end
end
