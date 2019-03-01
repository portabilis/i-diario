class RemoveVisibleFromStudentEnrollmentClassroom < ActiveRecord::Migration
  def change
    remove_column :student_enrollment_classrooms, :visible, :boolean
  end
end
