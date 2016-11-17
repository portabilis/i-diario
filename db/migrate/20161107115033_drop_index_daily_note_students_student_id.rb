class DropIndexDailyNoteStudentsStudentId < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP INDEX index_daily_note_students_on_daily_note_id_and_student_id;
    SQL
  end
end
