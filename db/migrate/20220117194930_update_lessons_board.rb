class UpdateLessonsBoard < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE lessons_boards
         SET classrooms_grade_id = (
           SELECT classrooms_grades.id
             FROM classrooms_grades
            WHERE classrooms_grades.classroom_id = lessons_boards.classroom_id
            LIMIT 1
         )
    SQL
  end
end
