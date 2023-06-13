class AddLastActivityAtToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_activity_at, :datetime, default: Date.current
  end
end
