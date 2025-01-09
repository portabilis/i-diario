class CreateUserPermissions < ActiveRecord::Migration[5.0]
  def change
    create_table :user_permissions do |t|
      t.integer :user_id, foreign_key: true
      t.string :feature, null: false
      t.string :permission, null: false

      t.timestamps
    end
    add_index :user_permissions, [:user_id, :feature], unique: true
    add_index :user_permissions, :user_id
  end
end
