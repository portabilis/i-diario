class AddColumnIndexToStudentEnrollmentClassroom < ActiveRecord::Migration
  def change
    add_column :student_enrollment_classrooms, :index, :integer
  end
end
