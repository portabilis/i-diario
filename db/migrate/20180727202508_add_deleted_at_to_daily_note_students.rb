class AddDeletedAtToDailyNoteStudents < ActiveRecord::Migration
  def change
    add_column :daily_note_students, :deleted_at, :datetime
    add_index :daily_note_students, :deleted_at
  end
end
