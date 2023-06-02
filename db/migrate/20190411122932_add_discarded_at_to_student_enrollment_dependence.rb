class AddDiscardedAtToStudentEnrollmentDependence < ActiveRecord::Migration[4.2]
  def up
    add_column :student_enrollment_dependences, :discarded_at, :datetime
    add_index :student_enrollment_dependences, :discarded_at
  end

  def down
    remove_column :student_enrollment_dependences, :discarded_at
  end
end
