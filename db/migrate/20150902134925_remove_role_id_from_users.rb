class RemoveRoleIdFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :role_id
  end
end
