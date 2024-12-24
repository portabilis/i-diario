class AddUniqueIndexToRecoveryDiaryRecordStudents < ActiveRecord::Migration[4.2]
  def change
    execute 'DROP INDEX IF EXISTS index_on_recovery_diary_record_id_and_student_id'
    add_index :recovery_diary_record_students, [:recovery_diary_record_id, :student_id], unique: true,
      name: 'index_unique_on_recovery_diary_record_students'
  end
end
