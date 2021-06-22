class AddPasswordChangeAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :password_changed_at, :datetime, default: Date.current
  end
end
