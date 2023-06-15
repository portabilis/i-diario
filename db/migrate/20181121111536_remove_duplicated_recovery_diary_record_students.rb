class RemoveDuplicatedRecoveryDiaryRecordStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE recovery_diary_record_student record;
        DECLARE last_recovery_diary_record_student_id INT;
      BEGIN
        FOR recovery_diary_record_student IN (
          SELECT recovery_diary_record_id,
                 student_id
            FROM recovery_diary_record_students
        GROUP BY recovery_diary_record_id, student_id
          HAVING COUNT(1) > 1
        )
        LOOP
          SELECT MAX(id)
            INTO last_recovery_diary_record_student_id
            FROM recovery_diary_record_students
           WHERE recovery_diary_record_id = recovery_diary_record_student.recovery_diary_record_id
             AND student_id = recovery_diary_record_student.student_id;

          DELETE
            FROM recovery_diary_record_students
           WHERE id <> last_recovery_diary_record_student_id
             AND recovery_diary_record_id = recovery_diary_record_student.recovery_diary_record_id
             AND student_id = recovery_diary_record_student.student_id;
        END LOOP;
      END$$;
    SQL
  end
end
