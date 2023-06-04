class CreateRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :roles do |t|
      t.integer :author_id, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true
    add_index :roles, :author_id
    add_foreign_key :roles, :users, column: :author_id
  end
end
