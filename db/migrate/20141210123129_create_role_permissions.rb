class CreateRolePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :role_permissions do |t|
      t.integer :role_id, null: false
      t.string :feature, null: false
      t.string :permission, null: false

      t.timestamps
    end
    add_index :role_permissions, [:role_id, :feature], unique: true
    add_index :role_permissions, :role_id
    add_foreign_key :role_permissions, :roles
  end
end
