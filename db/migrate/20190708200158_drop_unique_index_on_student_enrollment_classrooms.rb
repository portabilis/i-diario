class DropUniqueIndexOnStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute 'DROP INDEX IF EXISTS student_enrollment_classrooms_unique_index'
  end
end
