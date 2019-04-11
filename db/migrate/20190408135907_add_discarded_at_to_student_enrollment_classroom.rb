class AddDiscardedAtToStudentEnrollmentClassroom < ActiveRecord::Migration
  def change
    add_column :student_enrollment_classrooms, :discarded_at, :datetime
    add_index :student_enrollment_classrooms, :discarded_at
  end
end
