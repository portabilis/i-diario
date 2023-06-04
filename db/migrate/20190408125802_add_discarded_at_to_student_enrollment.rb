class AddDiscardedAtToStudentEnrollment < ActiveRecord::Migration[4.2]
  def up
    add_column :student_enrollments, :discarded_at, :datetime
    add_index :student_enrollments, :discarded_at
  end

  def down
    remove_column :student_enrollments, :discarded_at
  end
end
