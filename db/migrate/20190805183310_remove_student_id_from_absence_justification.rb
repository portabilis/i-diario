class RemoveStudentIdFromAbsenceJustification < ActiveRecord::Migration[4.2]
  def change
    remove_column :absence_justifications, :student_id, :integer
  end
end
