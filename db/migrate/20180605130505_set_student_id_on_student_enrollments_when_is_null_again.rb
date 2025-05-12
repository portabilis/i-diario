class SetStudentIdOnStudentEnrollmentsWhenIsNullAgain < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE student_enrollments SET student_id = students.id
        FROM students
       WHERE students.api_code = student_code
         AND student_id IS NULL;
    SQL
  end
end
