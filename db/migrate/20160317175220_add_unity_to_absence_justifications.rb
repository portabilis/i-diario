class AddUnityToAbsenceJustifications < ActiveRecord::Migration
  def change
    add_reference :absence_justifications, :unity, index: true, foreign_key: true
  end
end
