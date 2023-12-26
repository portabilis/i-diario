class RemoveUnneededIndexOnRecoveryDiaryRecordId < ActiveRecord::Migration[4.2]
  def change
    remove_index :recovery_diary_record_students, name: "index_on_recovery_diary_record_id"
  end

  def down
    execute %{
      CREATE INDEX index_on_recovery_diary_record_id ON public.recovery_diary_record_students USING btree (recovery_diary_record_id);
    }
  end
end
