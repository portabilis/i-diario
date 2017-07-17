class AlterTable***REMOVED***sSetColumn***REMOVED***IdNull < ActiveRecord::Migration
  def change
    execute <<-SQL
      ALTER TABLE ***REMOVED*** ALTER COLUMN measuring_unit_id DROP NOT NULL;
    SQL
  end
end
