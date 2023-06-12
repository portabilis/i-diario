class FixDailyNoteStudentsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :daily_note_students, column: [:daily_note_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :daily_note_students, column: [:student_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :daily_note_students, :daily_note_id, algorithm: :concurrently
    add_index :daily_note_students, :student_id, algorithm: :concurrently
  end
end
