class AddIdToAbsenceJustificationsStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :absence_justifications_students, :id, :primary_key
  end
end
