class AddDiscardedAtToStudentEnrollmentExemptedDiscipline < ActiveRecord::Migration[4.2]
  def up
    add_column :student_enrollment_exempted_disciplines, :discarded_at, :datetime
    add_index :student_enrollment_exempted_disciplines, :discarded_at
  end

  def down
    remove_column :student_enrollment_exempted_disciplines, :discarded_at
  end
end
