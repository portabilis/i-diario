class AddColumnIndexToStudentEnrollmentClassroom < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollment_classrooms, :index, :integer
  end
end
