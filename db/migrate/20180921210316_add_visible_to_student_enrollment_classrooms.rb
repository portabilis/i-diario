class AddVisibleToStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollment_classrooms, :visible, :boolean, default: true
  end
end
