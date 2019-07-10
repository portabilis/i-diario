class DropUniqueIndexOnStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    execute 'DROP INDEX IF EXISTS student_enrollment_classrooms_unique_index'
  end
end
