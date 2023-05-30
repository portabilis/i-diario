class RemoveUnneededIndexFinalRecoveryDiaryRecordsOnRecoveryDiaryRecordId < ActiveRecord::Migration[4.2]
  def change
    remove_index :final_recovery_diary_records, name: "index_final_recovery_diary_records_on_recovery_diary_record_id"
  end

  def down
    execute %{
      CREATE INDEX index_final_recovery_diary_records_on_recovery_diary_record_id ON public.final_recovery_diary_records USING btree (recovery_diary_record_id);
    }
  end
end
