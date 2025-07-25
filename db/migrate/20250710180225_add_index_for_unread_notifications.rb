class AddIndexForUnreadNotifications < ActiveRecord::Migration
  disable_ddl_transaction!
  
  def change
    add_index :system_notification_targets, [:user_id, :read], 
              name: 'index_snt_on_user_id_and_read',
              algorithm: :concurrently
  end
end