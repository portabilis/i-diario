class AddPeriodToAbsenceJustifications < ActiveRecord::Migration[5.0]
  def change
    add_column :absence_justifications, :period, :integer
  end
end
