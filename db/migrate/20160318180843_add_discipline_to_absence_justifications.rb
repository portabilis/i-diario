class AddDisciplineToAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    add_reference :absence_justifications, :discipline, index: true, foreign_key: true
  end
end
