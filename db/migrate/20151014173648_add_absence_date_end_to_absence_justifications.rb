class AddAbsenceDateEndToAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    add_column :absence_justifications, :absence_date_end, :date

    execute <<-SQL
      UPDATE absence_justifications
      SET absence_date_end = absence_date
      WHERE absence_date_end is null;
    SQL

    change_column :absence_justifications, :absence_date_end, :date, null: false
  end
end