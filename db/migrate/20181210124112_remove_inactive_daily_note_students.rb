class RemoveInactiveDailyNoteStudents < ActiveRecord::Migration
  def change
    execute <<-SQL
      DELETE
        FROM daily_note_students
       WHERE NOT active
         AND note IS NULL;
    SQL
  end
end
