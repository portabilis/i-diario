class AddClassroomToAbsenceJustifications < ActiveRecord::Migration
  def change
    add_reference :absence_justifications, :classroom, index: true, foreign_key: true
  end
end
