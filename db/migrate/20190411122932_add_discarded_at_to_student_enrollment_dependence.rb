class AddDiscardedAtToStudentEnrollmentDependence < ActiveRecord::Migration
  def change
    add_column :student_enrollment_dependences, :discarded_at, :datetime
    add_index :student_enrollment_dependences, :discarded_at
  end
end
