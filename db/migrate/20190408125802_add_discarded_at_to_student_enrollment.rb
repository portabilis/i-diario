class AddDiscardedAtToStudentEnrollment < ActiveRecord::Migration
  def change
    add_column :student_enrollments, :discarded_at, :datetime
    add_index :student_enrollments, :discarded_at
  end
end
