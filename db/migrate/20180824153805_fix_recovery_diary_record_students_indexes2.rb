class FixRecoveryDiaryRecordStudentsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :recovery_diary_record_students, name: :index_on_recovery_diary_record_id_and_student_id, algorithm: :concurrently
    remove_index :recovery_diary_record_students, name: :index_on_recovery_diary_record_id, algorithm: :concurrently
    remove_index :recovery_diary_record_students, column: [:student_id], algorithm: :concurrently

    add_index :recovery_diary_record_students, [:recovery_diary_record_id, :student_id], name: :index_on_recovery_diary_record_id_and_student_id, algorithm: :concurrently
    add_index :recovery_diary_record_students, :recovery_diary_record_id, name: :index_on_recovery_diary_record_id, algorithm: :concurrently
    add_index :recovery_diary_record_students, :student_id, algorithm: :concurrently
  end
end
