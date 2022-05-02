class AddIndexToCreatedAtOnSystemNotifications < ActiveRecord::Migration
  def change
    add_index :system_notifications, :created_at
  end
end
