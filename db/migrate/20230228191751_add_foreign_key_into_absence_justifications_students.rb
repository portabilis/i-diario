class AddForeignKeyIntoAbsenceJustificationsStudents < ActiveRecord::Migration
  def change
    add_foreign_key :absence_justifications_students, :absence_justifications, foreign_key: true
  end
end
