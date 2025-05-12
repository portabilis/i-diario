class AddIndexesForSystemNotificationsQueryOptimization < ActiveRecord::Migration[5.0]
  def up
    add_index :system_notification_targets, [:user_id, :system_notification_id], name: 'index_snt_on_user_id_and_notification_id'
    add_index :system_notifications, [:id, :created_at], name: 'index_sn_on_id_and_created_at'
  end

  def down
    remove_index :system_notification_targets, name: 'index_snt_on_user_id_and_notification_id'
    remove_index :system_notifications, name: 'index_sn_on_id_and_created_at'
  end
end
