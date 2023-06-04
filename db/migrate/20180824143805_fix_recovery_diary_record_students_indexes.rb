class FixRecoveryDiaryRecordStudentsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :recovery_diary_record_students, name: :index_on_recovery_diary_record_id_and_student_id
    remove_index :recovery_diary_record_students, name: :index_on_recovery_diary_record_id
    remove_index :recovery_diary_record_students, :student_id

    add_index :recovery_diary_record_students, [:recovery_diary_record_id, :student_id], where: "deleted_at IS NULL", name: :index_on_recovery_diary_record_id_and_student_id
    add_index :recovery_diary_record_students, :recovery_diary_record_id, where: "deleted_at IS NULL", name: :index_on_recovery_diary_record_id
    add_index :recovery_diary_record_students, :student_id, where: "deleted_at IS NULL"
  end
end
