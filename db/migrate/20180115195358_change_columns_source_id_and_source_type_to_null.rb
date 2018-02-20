class ChangeColumnsSourceIdAndSourceTypeToNull < ActiveRecord::Migration
  def change
    change_column_null :system_***REMOVED***, :source_id, true
    change_column_null :system_***REMOVED***, :source_type, true
  end
end
