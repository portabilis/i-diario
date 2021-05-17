class UpdateAvaliations < ActiveRecord::Migration
  def change
    execute <<-SQL
    UPDATE avaliations
       SET classroom_grade_id = (
         SELECT classroom_grades.id
           FROM classroom_grades
          WHERE classroom_grades.classroom_id = avaliations.classroom_id
          LIMIT 1
    )
    SQL
  end
end
