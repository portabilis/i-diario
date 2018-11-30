class ChangeColumnsSourceIdAndSourceTypeToNull < ActiveRecord::Migration
  def change
    change_column_null :system_notifications, :source_id, true
    change_column_null :system_notifications, :source_type, true
  end
end
