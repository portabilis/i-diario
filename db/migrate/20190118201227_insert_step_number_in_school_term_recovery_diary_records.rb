class InsertStepNumberInSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE school_term_recovery_diary_records
         SET step_number = (
           SELECT COALESCE(MAX(step.step_number), 0)
             FROM step_by_classroom(
                    recovery_diary_records.classroom_id,
                    recovery_diary_records.recorded_at
                  ) AS step
         )
        FROM recovery_diary_records
       WHERE recovery_diary_records.id = school_term_recovery_diary_records.recovery_diary_record_id
    SQL
  end
end
