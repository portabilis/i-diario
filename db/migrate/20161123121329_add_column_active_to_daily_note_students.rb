class AddColumnActiveToDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_note_students, :active, :boolean
  end
end
