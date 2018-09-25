class AddIndexVisibleToStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    add_index :student_enrollment_classrooms, :visible
  end
end
