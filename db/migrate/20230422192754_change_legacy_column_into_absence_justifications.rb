class ChangeLegacyColumnIntoAbsenceJustifications < ActiveRecord::Migration
  def change
    change_column :absence_justifications, :legacy, :boolean, default: false
  end
end
