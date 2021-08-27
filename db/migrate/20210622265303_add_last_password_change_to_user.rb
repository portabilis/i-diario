class AddLastPasswordChangeToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_password_change, :datetime, default: Date.current
  end
end
