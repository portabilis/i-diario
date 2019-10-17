class AddDiscardedAtToDailyNoteStudents < ActiveRecord::Migration
  def change
    add_column :daily_note_students, :discarded_at, :datetime
  end
end
