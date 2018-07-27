class AddDeletedAtToRecoveryDiaryRecordStudents < ActiveRecord::Migration
  def change
    add_column :recovery_diary_record_students, :deleted_at, :datetime
    add_index :recovery_diary_record_students, :deleted_at
  end
end
