class AddIndexStudentEnrollmentIdToStudentEnrollmentClassrooms < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :student_enrollment_classrooms, :student_enrollment_id, 
              algorithm: :concurrently unless index_exists?(:student_enrollment_classrooms, :student_enrollment_id)
  end
  
  def down
    remove_index :student_enrollment_classrooms, :student_enrollment_id if index_exists?(:student_enrollment_classrooms, :student_enrollment_id)
  end
end