class RemoveRoleIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :role_id
  end
end
