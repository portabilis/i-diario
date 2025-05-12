class AddActivedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :actived_at, :datetime
  end
end
