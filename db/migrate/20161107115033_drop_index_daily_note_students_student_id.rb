class DropIndexDailyNoteStudentsStudentId < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP INDEX index_daily_note_students_on_daily_note_id_and_student_id;
    SQL
  end
end
