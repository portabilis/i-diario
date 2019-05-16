class AddUniqueIndexToUserLogin < ActiveRecord::Migration
  def change
    add_index :users, :login, unique: true, where: "COALESCE(login, '') <> ''"
  end
end
