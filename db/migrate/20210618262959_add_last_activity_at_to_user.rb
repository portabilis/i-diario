class AddLastActivityAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_activity_at, :datetime, default: Date.current
  end
end
