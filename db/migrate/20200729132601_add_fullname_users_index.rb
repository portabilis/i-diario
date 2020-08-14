class AddFullnameUsersIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :users, :fullname, using: :btree, algorithm: :concurrently
  end
end
