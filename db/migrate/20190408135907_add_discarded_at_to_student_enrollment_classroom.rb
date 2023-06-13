class AddDiscardedAtToStudentEnrollmentClassroom < ActiveRecord::Migration[4.2]
  def up
    add_column :student_enrollment_classrooms, :discarded_at, :datetime
    add_index :student_enrollment_classrooms, :discarded_at
  end

  def down
    remove_column :student_enrollment_classrooms, :discarded_at
  end
end
