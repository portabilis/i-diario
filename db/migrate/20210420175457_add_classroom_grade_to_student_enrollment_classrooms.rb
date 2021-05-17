class AddClassroomGradeToStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    add_column :student_enrollment_classrooms, :classroom_grade_id, :integer
  end
end
