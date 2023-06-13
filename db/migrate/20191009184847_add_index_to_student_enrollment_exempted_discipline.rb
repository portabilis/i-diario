class AddIndexToStudentEnrollmentExemptedDiscipline < ActiveRecord::Migration[4.2]
  def change
    add_index :student_enrollment_exempted_disciplines, [:student_enrollment_id, :discipline_id],
              name: 'idx_student_enrollment_exempted_disciplines'
  end
end
