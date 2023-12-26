class RemoveIndexToStudentEnrollmentExemptedDiscipline < ActiveRecord::Migration[4.2]
  def change
    remove_index :student_enrollment_exempted_disciplines, name: 'idx_student_enrollment_exempted_disciplines'
  end
end
