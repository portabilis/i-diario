class AddGenericToSystemNotifications < ActiveRecord::Migration
  def change
    add_column :system_notifications, :generic, :boolean, default: false
  end
end
