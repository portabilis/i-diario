class AddDiscardedAtToRecoveryDiaryRecordStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :recovery_diary_record_students, :discarded_at, :datetime

    remove_index :recovery_diary_record_students, name: 'index_unique_on_recovery_diary_record_students'

    add_index(
      :recovery_diary_record_students,
      [:recovery_diary_record_id, :student_id, :discarded_at],
      unique: true,
      name: 'index_unique_on_recovery_diary_record_students'
    )
  end
end
