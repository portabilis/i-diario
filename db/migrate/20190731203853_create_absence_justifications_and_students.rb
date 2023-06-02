class CreateAbsenceJustificationsAndStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :absence_justifications_students, id: false do |t|
      t.belongs_to :student, null: false
      t.belongs_to :absence_justification, null: false
    end
  end
end
