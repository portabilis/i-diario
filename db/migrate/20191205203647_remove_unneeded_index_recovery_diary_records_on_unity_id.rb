class RemoveUnneededIndexRecoveryDiaryRecordsOnUnityId < ActiveRecord::Migration[4.2]
  def change
    remove_index :recovery_diary_records, name: "index_recovery_diary_records_on_unity_id"
  end

  def down
    execute %{
      CREATE INDEX index_recovery_diary_records_on_unity_id ON public.recovery_diary_records USING btree (unity_id);
    }
  end
end
