class MigrateLegacyAbsenceJustifications < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE absence_justifications
         SET legacy = true
       WHERE extract(year from absence_date) < 2023
    SQL
  end
end
