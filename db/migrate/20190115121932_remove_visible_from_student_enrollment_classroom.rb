class RemoveVisibleFromStudentEnrollmentClassroom < ActiveRecord::Migration[4.2]
  def change
    remove_column :student_enrollment_classrooms, :visible, :boolean
  end
end
