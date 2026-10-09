class AddClassroomsGradeIdIndexToStudentEnrollmentClassrooms < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    add_index :student_enrollment_classrooms, :classrooms_grade_id, algorithm: :concurrently
  end

  def down
    remove_index :student_enrollment_classrooms, column: :classrooms_grade_id, algorithm: :concurrently
  end
end
