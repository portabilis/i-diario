class AlterColumn***REMOVED***IdNull < ActiveRecord::Migration
  def change
    execute "ALTER TABLE ***REMOVED***s DROP COLUMN ***REMOVED***_type_id"
    execute "ALTER TABLE ***REMOVED***s ADD COLUMN ***REMOVED***_type_id int"
  end
end
