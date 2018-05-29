class AddGenericToSystemNotifications < ActiveRecord::Migration
  def change
    add_column :system_***REMOVED***, :generic, :boolean, default: false
  end
end
