class RecreateIndexOnRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    remove_index :recovery_diary_records, name: 'idx_unity_id_and_classroom_id_and_discipline_id_and_recorded_at'

    add_index(
      :recovery_diary_records,
      [:unity_id, :classroom_id, :discipline_id],
      unique: false,
      name: 'idx_unity_id_and_classroom_id_and_discipline_id'
    )
  end
end
