class MigrateAbsenceJustificationsStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE
        absence_justification RECORD;
      BEGIN
        FOR absence_justification IN (
          SELECT id, student_id
            FROM absence_justifications
        ) LOOP
          INSERT
            INTO absence_justifications_students (
              absence_justification_id,
              student_id
            )
          VALUES (
            absence_justification.id,
            absence_justification.student_id
          );
        END LOOP;
      END$$
    SQL
  end
end
