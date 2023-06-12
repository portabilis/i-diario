class AddCurrentUserRoleIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_user_role_id, :integer, null: true

    add_foreign_key :users, :user_roles, column: :current_user_role_id
    add_index :users, :current_user_role_id, unique: true
  end
end
