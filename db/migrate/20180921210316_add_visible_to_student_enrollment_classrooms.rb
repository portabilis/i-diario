class AddVisibleToStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    add_column :student_enrollment_classrooms, :visible, :boolean, default: true
  end
end
