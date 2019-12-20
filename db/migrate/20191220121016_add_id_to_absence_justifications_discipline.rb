class AddIdToAbsenceJustificationsDiscipline < ActiveRecord::Migration
  def change
    add_column :absence_justifications_disciplines, :id, :primary_key
  end
end
