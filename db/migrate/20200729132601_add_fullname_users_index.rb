class AddFullnameUsersIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :users, :fullname, using: :btree, algorithm: :concurrently
  end
end
