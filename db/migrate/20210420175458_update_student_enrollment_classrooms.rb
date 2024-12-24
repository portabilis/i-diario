class UpdateStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE student_enrollment_classrooms
         SET classrooms_grade_id = (
           SELECT classrooms_grades.id
             FROM classrooms_grades
            WHERE classrooms_grades.classroom_id = student_enrollment_classrooms.classroom_id
            LIMIT 1
         )
    SQL
  end
end
