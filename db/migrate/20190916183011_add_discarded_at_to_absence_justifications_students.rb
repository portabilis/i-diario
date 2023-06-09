class AddDiscardedAtToAbsenceJustificationsStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :absence_justifications_students, :discarded_at, :datetime

    add_index(
      :absence_justifications_students,
      [:absence_justification_id, :student_id, :discarded_at],
      unique: true,
      name: 'absence_justification_id_student_id_idx'
    )
  end
end
