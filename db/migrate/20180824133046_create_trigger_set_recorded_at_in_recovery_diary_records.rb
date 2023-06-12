class CreateTriggerSetRecordedAtInRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE TRIGGER trigger_set_recorded_at_in_recovery_diary_records
      BEFORE INSERT OR UPDATE ON school_term_recovery_diary_records
      FOR EACH ROW
      EXECUTE PROCEDURE set_recorded_at_in_recovery_diary_records();
    SQL
  end
end
