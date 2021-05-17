class UpdateStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE student_enrollment_classrooms
         SET classroom_grade_id = (
           SELECT classroom_grades.id
             FROM classroom_grades
            WHERE classroom_grades.classroom_id = student_enrollment_classrooms.classroom_id
            LIMIT 1
         )
    SQL
  end
end
