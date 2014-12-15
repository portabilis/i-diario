class AddRoleIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :role_id, :integer
    add_index :users, :role_id
    add_foreign_key :users, :roles
  end
end
