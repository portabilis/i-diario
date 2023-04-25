class AddDeletedAtToDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_note_students, :deleted_at, :datetime
    add_index :daily_note_students, :deleted_at
  end
end
