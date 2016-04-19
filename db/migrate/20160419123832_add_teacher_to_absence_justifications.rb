class AddTeacherToAbsenceJustifications < ActiveRecord::Migration
  def change
    add_reference :absence_justifications, :teacher, index: true, foreign_key: true
  end
end
