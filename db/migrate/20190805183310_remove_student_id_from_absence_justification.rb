class RemoveStudentIdFromAbsenceJustification < ActiveRecord::Migration
  def change
    remove_column :absence_justifications, :student_id, :integer
  end
end
