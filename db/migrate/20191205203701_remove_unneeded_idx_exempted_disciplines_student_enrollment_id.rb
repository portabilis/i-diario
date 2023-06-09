class RemoveUnneededIdxExemptedDisciplinesStudentEnrollmentId < ActiveRecord::Migration[4.2]
  def change
    remove_index :student_enrollment_exempted_disciplines, name: "idx_exempted_disciplines_student_enrollment_id"
  end

  def down
    execute %{
      CREATE INDEX idx_exempted_disciplines_student_enrollment_id ON public.student_enrollment_exempted_disciplines USING btree (student_enrollment_id);
    }
  end
end
