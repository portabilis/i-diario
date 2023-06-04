class DeleteDuplicatedDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM daily_note_students
       USING daily_note_students AS daily_note_students_to_delete
       WHERE daily_note_students.id < daily_note_students_to_delete.id
         AND daily_note_students.student_id = daily_note_students_to_delete.student_id
         AND daily_note_students.daily_note_id = daily_note_students_to_delete.daily_note_id;
    SQL
  end
end
