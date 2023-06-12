class FixRecoveryDiaryRecordsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :recovery_diary_records, name: :idx_unity_id_and_classroom_id_and_discipline_id, algorithm: :concurrently
    remove_index :recovery_diary_records, column: [:unity_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :recovery_diary_records, column: [:classroom_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :recovery_diary_records, column: [:discipline_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :recovery_diary_records, [:unity_id, :classroom_id, :discipline_id], name: :idx_unity_id_and_classroom_id_and_discipline_id, algorithm: :concurrently
    add_index :recovery_diary_records, :unity_id, algorithm: :concurrently
    add_index :recovery_diary_records, :classroom_id, algorithm: :concurrently
    add_index :recovery_diary_records, :discipline_id, algorithm: :concurrently
  end
end
