class AddUniqueIndexToStudentEnrollmentExemptedDiscipline < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :student_enrollment_exempted_disciplines, [:student_enrollment_id, :discipline_id],
              name: 'idx_unique_student_enrollment_exempted_disciplines', unique: true, algorithm: :concurrently
  end
end
