class FixDailyNoteStudentsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :daily_note_students, :daily_note_id
    remove_index :daily_note_students, :student_id

    add_index :daily_note_students, :daily_note_id, where: "deleted_at IS NULL"
    add_index :daily_note_students, :student_id, where: "deleted_at IS NULL"
  end
end
