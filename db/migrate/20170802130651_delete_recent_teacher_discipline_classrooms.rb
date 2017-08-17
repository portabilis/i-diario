class DeleteRecentTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    execute <<-SQL
      DELETE
        FROM teacher_discipline_classrooms
       WHERE year = 2017;
    SQL
  end
end
