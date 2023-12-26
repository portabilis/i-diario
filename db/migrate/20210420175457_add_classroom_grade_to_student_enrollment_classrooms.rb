class AddClassroomGradeToStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollment_classrooms, :classrooms_grade_id, :integer
  end
end
