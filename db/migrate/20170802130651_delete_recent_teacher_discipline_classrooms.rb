class DeleteRecentTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE
        FROM teacher_discipline_classrooms
       WHERE year = 2017;
    SQL
  end
end
