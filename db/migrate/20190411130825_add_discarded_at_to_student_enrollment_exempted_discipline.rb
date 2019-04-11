class AddDiscardedAtToStudentEnrollmentExemptedDiscipline < ActiveRecord::Migration
  def change
    add_column :student_enrollment_exempted_disciplines, :discarded_at, :datetime
    add_index :student_enrollment_exempted_disciplines, :discarded_at
  end
end
