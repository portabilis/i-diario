class AddUniqueIndexToUserLogin < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :login, unique: true, where: "COALESCE(login, '') <> ''"
  end
end
