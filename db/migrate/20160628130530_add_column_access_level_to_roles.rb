class AddColumnAccessLevelToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :access_level, :string
  end
end
