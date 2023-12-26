class RemoveInactiveDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE
        FROM daily_note_students
       WHERE NOT active
         AND note IS NULL;
    SQL
  end
end
