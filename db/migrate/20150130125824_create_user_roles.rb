class CreateUserRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :user_roles do |t|
      t.integer :user_id, null: false
      t.integer :role_id, null: false
      t.integer :unity_id

      t.timestamps
    end
    add_index :user_roles, :user_id
    add_index :user_roles, :role_id
    add_index :user_roles, :unity_id
    add_foreign_key :user_roles, :users
    add_foreign_key :user_roles, :roles
    add_foreign_key :user_roles, :unities
  end
end
