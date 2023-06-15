class AddFullnameToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :fullname, :string
  end
end
