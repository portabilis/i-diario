class AddIndexToCreatedAtOnSystemNotifications < ActiveRecord::Migration[4.2]
  def change
    add_index :system_notifications, :created_at
  end
end
