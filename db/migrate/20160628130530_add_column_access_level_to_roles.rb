class AddColumnAccessLevelToRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :roles, :access_level, :string
  end
end
