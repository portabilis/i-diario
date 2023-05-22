class AddLegacyColumnIntoAbsenceJustifications < ActiveRecord::Migration
  def change
    add_column :absence_justifications, :legacy, :boolean, default: true
  end
end
