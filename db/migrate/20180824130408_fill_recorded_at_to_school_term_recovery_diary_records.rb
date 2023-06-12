class FillRecordedAtToSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE school_term_recovery_diary_records
         SET recorded_at = (SELECT recorded_at
                              FROM recovery_diary_records AS rdr
                             WHERE rdr.id = school_term_recovery_diary_records.recovery_diary_record_id);
    SQL
  end
end
