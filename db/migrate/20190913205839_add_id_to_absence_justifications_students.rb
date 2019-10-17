class AddIdToAbsenceJustificationsStudents < ActiveRecord::Migration
  def change
    add_column :absence_justifications_students, :id, :primary_key
  end
end
