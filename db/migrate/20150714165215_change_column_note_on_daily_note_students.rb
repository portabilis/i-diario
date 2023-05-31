class ChangeColumnNoteOnDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    change_column :daily_note_students, :note, :decimal, precision: 7, scale: 3
  end
end
