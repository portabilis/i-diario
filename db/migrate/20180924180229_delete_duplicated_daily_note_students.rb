class DeleteDuplicatedDailyNoteStudents < ActiveRecord::Migration
  def change
    execute <<-SQL
    DELETE FROM daily_note_students AS t1
    USING daily_note_students AS t2
    WHERE t1.id < t2.id
    AND t1.student_id = t2.student_id
    AND t1.daily_note_id = t2.daily_note_id;
    SQL
  end
end
