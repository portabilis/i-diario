class SetDefaultValuesToColumnAccessLevel < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE roles SET access_level = 'parent' WHERE kind = 'parent';
      UPDATE roles SET access_level = 'student' WHERE kind = 'student';
      UPDATE roles SET access_level = 'teacher' WHERE kind = 'employee';
    SQL
  end
end
