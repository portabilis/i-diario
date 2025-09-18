class AddPartialIndexToSystemNotificationTargets < ActiveRecord::Migration[5.0]
  def up
    add_index :system_notification_targets, 
              :user_id, 
              where: "read = false",
              name: "index_snt_on_user_id_unread"
  end

  def down
    remove_index :system_notification_targets, name: "index_snt_on_user_id_unread"
  end
end