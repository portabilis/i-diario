class AddDisciplineToAbsenceJustifications < ActiveRecord::Migration
  def change
    add_reference :absence_justifications, :discipline, index: true, foreign_key: true
  end
end
