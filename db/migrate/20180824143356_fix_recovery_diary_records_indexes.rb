class FixRecoveryDiaryRecordsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :recovery_diary_records, name: :idx_unity_id_and_classroom_id_and_discipline_id
    remove_index :recovery_diary_records, :unity_id
    remove_index :recovery_diary_records, :classroom_id
    remove_index :recovery_diary_records, :discipline_id

    add_index :recovery_diary_records, [:unity_id, :classroom_id, :discipline_id], where: "deleted_at IS NULL", name: :idx_unity_id_and_classroom_id_and_discipline_id
    add_index :recovery_diary_records, :unity_id, where: "deleted_at IS NULL"
    add_index :recovery_diary_records, :classroom_id, where: "deleted_at IS NULL"
    add_index :recovery_diary_records, :discipline_id, where: "deleted_at IS NULL"
  end
end
