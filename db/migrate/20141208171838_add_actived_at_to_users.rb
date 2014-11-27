class AddActivedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :actived_at, :datetime
  end
end
