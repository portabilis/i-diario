class AddLastPasswordChangeToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_password_change, :datetime, default: Date.current
  end
end
