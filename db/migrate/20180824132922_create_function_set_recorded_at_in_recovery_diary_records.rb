class CreateFunctionSetRecordedAtInRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION set_recorded_at_in_recovery_diary_records()
      RETURNS trigger AS $BODY$
      BEGIN
        UPDATE recovery_diary_records
           SET recorded_at = new.recorded_at
         WHERE id = new.recovery_diary_record_id;

        RETURN new;
      END;
      $BODY$ LANGUAGE plpgsql;
    SQL
  end
end
