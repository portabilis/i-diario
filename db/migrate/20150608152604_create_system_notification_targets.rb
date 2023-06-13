class CreateSystemNotificationTargets < ActiveRecord::Migration[4.2]
  def change
    create_table :system_notification_targets do |t|
      t.integer :system_notification_id, null: false
      t.integer :user_id, null: false
      t.boolean :read, default: false

      t.timestamps
    end
    add_index :system_notification_targets, :system_notification_id
    add_index :system_notification_targets, :user_id
    add_foreign_key :system_notification_targets, :users
  end
end
