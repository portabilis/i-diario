class AddGenericToSystemNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :system_notifications, :generic, :boolean, default: false
  end
end
