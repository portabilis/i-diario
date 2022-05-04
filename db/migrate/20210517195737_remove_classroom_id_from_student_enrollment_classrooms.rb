class RemoveClassroomIdFromStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    remove_column :student_enrollment_classrooms, :classroom_id
  end
end
